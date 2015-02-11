# version-control-distributor

## A little script that puts the 'Distributed' back in 'Distributed Version Control'

If you:

  * have a local repo that pushes to one of Github or Bitbucket
  * have an empty repo with the same name hosted at the other site, and
  * want to push code to both repos, simply run:


    vcd.sh ~/path/to/repository/

If the empty repo has a different name:

    vcd.sh ~/path/to/repository/ <empty_repo_name>

Once that's done, run `git remote -v`. The result should look something like this:

    $ git remote -v
    bitbucket       git@bitbucket.org:avnestico/version-control-distributor.git (fetch)
    bitbucket       git@bitbucket.org:avnestico/version-control-distributor.git (push)
    github  git@github.com:avnestico/version-control-distributor.git (fetch)
    github  git@github.com:avnestico/version-control-distributor.git (push)
    origin  git@github.com:avnestico/version-control-distributor.git (fetch)
    origin  git@github.com:avnestico/version-control-distributor.git (push)
    origin  git@bitbucket.org:avnestico/version-control-distributor.git (push)

`vcd.sh` doesn't change the pull source for your code. You will continue to pull from the original repo even as you push to both.

From now on, all you need to do is `git push` and your code will be mirrored on both remote repositories.
