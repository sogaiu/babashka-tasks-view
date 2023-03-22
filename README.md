# babashka-tasks-view (btv)

Suppose the content of a `bb.edn` is:

```edn
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
```

With `btv`, one can do:

```
$ btv rust
task-a   Check Rust capabilities
```

```
$ btv js
task-b   Check JavaScript capabilities
```

```
$ btv dependency
task-a   Check Rust capabilities
task-b   Check JavaScript capabilities
```

```
$ btv
task-a   Check Rust capabilities
task-b   Check JavaScript capabilities
task-c
```

```
$ btv --tags
dependency
js
play
rust
```
