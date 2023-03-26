(declare-project
  :name "babashka-tasks-view"
  :url "https://github.com/sogaiu/babashka-tasks-view"
  :repo "git+https://github.com/sogaiu/babashka-tasks-view.git")

(declare-executable
  :name "bbtv"
  :entry "babashka-tasks-view/bbtv.janet"
  :install true)

