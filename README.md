# babashka-tasks-view (bbtv)

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

With `bbtv`, one can do:

```
$ bbtv --tags
dependency
js
play
rust
```

```
$ bbtv rust
task-a   Check Rust capabilities
```

```
$ bbtv js
task-b   Check JavaScript capabilities
```

```
$ bbtv dependency
task-a   Check Rust capabilities
task-b   Check JavaScript capabilities
```

```
$ bbtv --tasks
task-a
task-b
task-c
```

```
$ bbtv
dependency
  task-a
  task-b

js
  task-b

play
  task-c

rust
  task-a
```

