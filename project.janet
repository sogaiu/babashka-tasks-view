(declare-project
  :name "babashka-tasks-view"
  :url "https://github.com/sogaiu/babashka-tasks-view"
  :repo "git+https://github.com/sogaiu/babashka-tasks-view.git")

(declare-executable
  :name "btv"
  :entry "babashka-tasks-view/btv.janet"
  :install true)

