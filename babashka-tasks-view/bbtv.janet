(import ./clojure-peg/clojure-peg/location :as l)
(import ./janet-zipper/janet-zipper/zipper :as c)
(import ./loc-cipper :as c)

(def usage
  ``
  Usage: bbtv [options]
         bbtv <tag>
  View Babashka tasks by tag.

    --help    show this output
    --tags    show all tags
    --tasks   show all tasks

  With no arguments, shows all tags with all associated tasks.

  Invoke in a directory that contains a bb.edn file.
  ``)

(defn has-bb-edn?
  []
  (os/stat "bb.edn"))

(defn drop-comments-and-discards
  [a-node]
  (filter |(not (match $
                  [:comment]
                  true
                  [:discard]
                  true))
          a-node))

(comment

  (def sample-src
    (string `{:min-bb-version "0.4.0"` "\n"
            ` :paths ["conf"` "\n"
            `         "script"]` "\n"
            ` :tasks {:requires ([babashka.fs :as fs]` "\n"
            `                    [conf :as cnf])` "\n"
            `         ;; underlying bits` "\n"
            `         task-a` "\n"
            `         {:doc "Check Rust capabilities"` "\n"
            `          :_tags [:rust :dependency]` "\n"
            `          :task check-rust-bits/-main}` "\n"
            `         task-b` "\n"
            `         {:doc "Check JavaScript capabilities"` "\n"
            `          :_tags [:js :dependency]` "\n"
            `          :task check-js-bits/-main}` "\n"
            `         task-c` "\n"
            `         {:_tags [:play]` "\n"
            `          :task fun/-main}` "\n"
            `         #_ #_ task-d` "\n"
            `         {:_tags [:dull]` "\n"
            `          :task work/-main}}}`))

  (def zloc
    (-> (l/par sample-src)
        c/zip-down))

  (def first-map-zloc
    (c/search-from zloc
                   |(match (c/node $)
                      [:map]
                      true)))

  (def tasks-keyword-zloc
    (c/search-from first-map-zloc
                   |(match (c/node $)
                      [:keyword _ value]
                      (= value ":tasks"))))

  (def tasks-map-zloc
    (c/right-until tasks-keyword-zloc
                   |(match (c/node $)
                      [:map]
                      true)))

  (def filtered-tasks-map-node
    (drop-comments-and-discards (c/node tasks-map-zloc)))

  (def tasks-as-jdn
    (l/gen (array/insert filtered-tasks-map-node 0 :code)))

  tasks-as-jdn
  # =>
  (string ":requires ([babashka.fs :as fs]\n"
          "                    [conf :as cnf])\n"
          "         \n"
          "         task-a\n"
          "         {:doc \"Check Rust capabilities\"\n"
          "          :_tags [:rust :dependency]\n"
          "          :task check-rust-bits/-main}\n"
          "         task-b\n"
          "         {:doc \"Check JavaScript capabilities\"\n"
          "          :_tags [:js :dependency]\n"
          "          :task check-js-bits/-main}\n"
          "         task-c\n"
          "         {:_tags [:play]\n"
          "          :task fun/-main}\n"
          "         ")

  )

(defn bb-edn-to-tasks-jdn
  [src]
  (def zloc
    (-> (l/par src)
        c/zip-down))

  (def first-map-zloc
    (c/search-from zloc
                   |(match (c/node $)
                      [:map]
                      true)))

  (def tasks-keyword-zloc
    (c/search-from first-map-zloc
                   |(match (c/node $)
                      [:keyword _ value]
                      (= value ":tasks"))))

  (def tasks-map-zloc
    (c/right-until tasks-keyword-zloc
                   |(match (c/node $)
                      [:map]
                      true)))

  (def filtered-tasks-map-node
    (drop-comments-and-discards (c/node tasks-map-zloc)))

  (l/gen (array/insert filtered-tasks-map-node 0 :code)))

(comment

  (def sample-src
    (string `{:min-bb-version "0.4.0"` "\n"
            ` :paths ["conf"` "\n"
            `         "script"]` "\n"
            ` :tasks {:requires ([babashka.fs :as fs]` "\n"
            `                    [conf :as cnf])` "\n"
            `         ;; underlying bits` "\n"
            `         task-a` "\n"
            `         {:doc "Check Rust capabilities"` "\n"
            `          :_tags [:rust :dependency]` "\n"
            `          :task check-rust-bits/-main}` "\n"
            `         task-b` "\n"
            `         {:doc "Check JavaScript capabilities"` "\n"
            `          :_tags [:js :dependency]` "\n"
            `          :task check-js-bits/-main}` "\n"
            `         task-c` "\n"
            `         {:_tags [:play]` "\n"
            `          :task fun/-main}` "\n"
            `         #_ #_ task-d` "\n"
            `         {:_tags [:dull]` "\n"
            `          :task work/-main}}}`))

  (bb-edn-to-tasks-jdn sample-src)
  # =>
  (string ":requires ([babashka.fs :as fs]\n"
          "                    [conf :as cnf])\n"
          "         \n"
          "         task-a\n"
          "         {:doc \"Check Rust capabilities\"\n"
          "          :_tags [:rust :dependency]\n"
          "          :task check-rust-bits/-main}\n"
          "         task-b\n"
          "         {:doc \"Check JavaScript capabilities\"\n"
          "          :_tags [:js :dependency]\n"
          "          :task check-js-bits/-main}\n"
          "         task-c\n"
          "         {:_tags [:play]\n"
          "          :task fun/-main}\n"
          "         ")

  )

(defn find-all-tags
  [task-names-and-tags]
  (->> (values task-names-and-tags)
               flatten
               distinct
               sort))

(defn print-tasks-with-doc
  [tasks-jdn tag]
  # XXX: should this always be over all task names or only those
  #      that "match"?
  (def longest-name-length
    (->> (keys tasks-jdn)
         (map length)
         splice
         max))

  (def min-spaces 3)

  (def tag-kwd
    (when tag
      (keyword tag)))

  (each name (sort (keys tasks-jdn))
    (def tags
      (get-in tasks-jdn [name :_tags]))

    (when (or (nil? tag)
              (and tags
                   (find |(= tag-kwd $) tags)))
      (def name-len
        (length name))
      (def doc-str
        (get-in tasks-jdn [name :doc]))
      (def spacer
        (string/repeat " "
                       (- (+ longest-name-length min-spaces)
                          name-len)))
      (printf "%s%s%s" name spacer doc-str))))

(comment

  (def sample-src
    ``
    {:min-bb-version "0.4.0"
     :paths ["conf"
             "script"]
     :tasks {:requires ([babashka.fs :as fs]
                        [conf :as cnf])
             ;; underlying bits
             task-a
             {:doc "Check Rust capabilities"
              :_tags [:rust :dependency]
              :task check-rust-bits/-main}
             task-b
             {:doc "Check JavaScript capabilities"
              :_tags [:js :dependency]
              :task check-js-bits/-main}
             task-c
             {:_tags [:play]
              :task fun/-main}
             #_ #_ task-d
             {:_tags [:dull]
              :task work/-main}}}
    ``)

  (def tasks-jdn
    (bb-edn-to-tasks-jdn sample-src))

  (def tweaked-tj
    (string "{" tasks-jdn "}"))

  (parse tweaked-tj)
  # =>
  '{task-a
    {:_tags [:rust :dependency]
     :doc "Check Rust capabilities"
     :task check-rust-bits/-main}
    task-b
    {:_tags [:js :dependency]
     :doc "Check JavaScript capabilities"
     :task check-js-bits/-main}
    task-c
    {:_tags [:play]
     :task fun/-main}
    :requires
    ([babashka.fs :as fs] [conf :as cnf])}

  )

(defn main
  [& argv]

  # XXX: improve args handling
  (when (or (not (has-bb-edn?))
            (when-let [arg (get argv 1)]
              (= "--help" arg)))
    (print usage)
    (os/exit 0))

  (def show-tags
    (when (> (length argv) 1)
      (= "--tags" (get argv 1))))

  (def show-tasks
    (when (> (length argv) 1)
      (= "--tasks" (get argv 1))))

  # XXX: only one tag at a time for the moment
  (def tag
    (when (> (length argv) 1)
      (let [cand (get argv 1)]
        (if (or (= "--tags" cand)
                (= "--tasks" cand))
          nil
          cand))))

  (def bb-edn
    (slurp "bb.edn"))

  (def tasks-jdn
    (bb-edn-to-tasks-jdn bb-edn))

  (def tweaked-tj
    (string "{" tasks-jdn "}"))

  (def tj
    (try
      (parse tweaked-tj)
      ([_]
        (eprint "Failed to parse bb.edn tasks")
        (os/exit 1))))

  (def task-names-and-tags
    (->> tj
         pairs
         (keep (fn [[k v]]
                 (when (symbol? k)
                   [k (v :_tags)])))
         from-pairs))

  (cond
    show-tasks
    (each name (sort (keys tj))
      (when (symbol? name)
        (print name)))
    #
    show-tags
    (each a-tag (sort (find-all-tags task-names-and-tags))
      (print a-tag))
    #
    tag
    (print-tasks-with-doc tj tag)
    #
    (each a-tag (find-all-tags task-names-and-tags)
      (print a-tag)
      (each task (sort (keys task-names-and-tags))
        (when (find |(= a-tag $)
                    (get task-names-and-tags task))
          (print "  " task)))
      (print))))

