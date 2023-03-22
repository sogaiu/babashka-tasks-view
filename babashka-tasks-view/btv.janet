(import ../clojure-peg/location :as l)
(import ../janet-zipper/zipper :as c)
(import ./loc-cipper :as c)

(defn has-bb-edn?
  []
  (os/stat "bb.edn"))

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
              :task fun/-main}}}
    ``)

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

  (-> tasks-map-zloc
      c/node
      l/gen)
  # =>
  (string "{:requires ([babashka.fs :as fs]\n"
          "                    [conf :as cnf])\n"
          "         ;; underlying bits\n"
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
          "          :task fun/-main}}")

  )

(defn drop-non-forms
  [a-node]
  (filter |(not (match $
                  [:whitespace]
                  true
                  [:comment]
                  true
                  [:discard]
                  true))
          a-node))

(comment

  (drop-non-forms
    [:map @{}
     [:keyword @{} ""] [:whitespace " "]
     [:number @{} "1"]])
  # =>
  '@[:map @{}
     (:keyword @{} "")
     (:number @{} "1")]

  )

(defn main
  [& argv]

  (when (or (not (has-bb-edn?))
            (when-let [arg (get argv 1)]
              (= "--help" arg)))
    (print "btv - view babashka tasks by tag")
    (print)
    (print "Invoke in a directory that contains a bb.edn file.")
    (os/exit 0))

  # XXX: only one tag at a time for the moment
  (def tag
    (when (> (length argv) 1)
      (get argv 1)))

  (def bb-edn
    (slurp "bb.edn"))

  (def zloc
    (-> (l/par bb-edn)
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
    (drop-non-forms (c/node tasks-map-zloc)))

  (def task-names
    (->> # drop :map and @{} from beginning
         (drop 2 filtered-tasks-map-node)
         # pair up nodes
         (partition 2)
         # just keep the first of the pair
         (map first)
         # retain only symbol names
         (keep |(match $
                  [:symbol _ value]
                    value))))

  (def task-values
    (as-> (drop 2 filtered-tasks-map-node) x
          # pair up nodes
          (partition 2 x)
          # only keep the associated values of symbol keys
          (keep (fn [pair]
                  (let [k (first pair)]
                    (when (= :symbol (first k))
                      (get pair 1))))
                x)))

  (def task-docs
    (map (fn [map-node]
           (->> # drop :map and @{} from beginning
                (drop 2 map-node)
                # drop the non-form nodes
                drop-non-forms
                # pair up nodes
                (partition 2)
                # get :doc node's associated string value if any
                (keep (fn [[k-node v-node]]
                        (let [[node-type _ node-value] k-node]
                          (when (and (= :keyword node-type)
                                     (= ":doc" node-value))
                            (get v-node 2)))))
                first))
         task-values))

  #(printf "docs: %M" task-docs)

  (def task-tags
    (map (fn [map-node]
           (->> # drop :map and @{} from beginning
                (drop 2 map-node)
                # drop the non-form nodes
                drop-non-forms
                # pair up nodes
                (partition 2)
                # get :_tags node's values if any
                (keep (fn [[k-node v-node]]
                        (let [[node-type _ node-value] k-node]
                          (when (and (= :keyword node-type)
                                     (= ":_tags" node-value))
                            (->> (drop 2 v-node)
                                 drop-non-forms
                                 (map |(get $ 2)))))))
                first))
         task-values))

  #(printf "tags: %M" task-tags)

  (def longest-name-length
    (max ;(map length task-names)))

  (def min-spaces 3)

  (def tag-str
    (when tag
      (string ":" tag)))

  (for i 0 (length task-names)
    (def name
      (get task-names i))

    (def tags
      (get task-tags i))

    (when (or (nil? tag)
              (and tags
                   (find |(= tag-str $) tags)))
      (def name-len
        (length name))
      (def doc
        (let [doc-str (get task-docs i "")]
          (if (pos? (length doc-str))
            (string/slice doc-str 1 -2)
            doc-str)))
      (def spacer
        (string/repeat " "
                       (- (+ longest-name-length min-spaces)
                          name-len)))
      (printf "%s%s%s" name spacer doc)))

  )
