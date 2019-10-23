Contributing to OpenJFX
=======================

OpenJFX is an open source project and we love to receive contributions from our community &mdash; you! There are many ways to contribute, from improving the documentation, submitting bug reports and feature requests or writing code which can be incorporated into OpenJFX itself.

Bug reports
-----------

If you think you have found a bug in OpenJFX, first make sure that you are testing against the latest version - your issue may already have been fixed. If not, search our [issues list](https://bugs.openjdk.java.net) in the Java Bug System (JBS) in case a similar issue has already been opened. More information on where and how to report a bug can be found at [bugreport.java.com](https://bugreport.java.com/).

It is very helpful if you can prepare a reproduction of the bug. In other words, provide a small test case which we can run to confirm your bug. It makes it easier to find the problem and to fix it.

Provide as much information as you can. The easier it is for us to recreate your problem, the faster it is likely to be fixed.

Feature requests
----------------

If you find yourself wishing for a feature that doesn't exist in OpenJFX, you are probably not alone. There are bound to be others out there with similar needs. Many of the features that OpenJFX has today have been added because our users saw the need.
Open an issue on our [issues list](https://bugs.openjdk.java.net) on JBS which describes the feature you would like to see, why you need it, and how it should work.

Contributing code and documentation changes
-------------------------------------------

If you have a bug fix or new feature that you would like to contribute to OpenJFX, please find or open an issue about it first. Talk about what you would like to do. It may be that somebody is already working on it, or that there are particular issues that you should know about before implementing the change. Feature requests, in particular, should be discussed ahead of time and will require significant effort on your part.

We enjoy working with contributors to get their code accepted. There are many approaches to fixing a problem and it is important to find the best approach before writing too much code.

Note that it is unlikely the project will merge refactors for the sake of refactoring. These
types of pull requests have a high cost to maintainers in reviewing and testing with little
to no tangible benefit. This especially includes changes generated by tools. For example,
converting all generic interface instances to use the diamond operator.

### Fork and clone the repository

Once you have created a bug report or confirmed its existence on JBS, you will need to fork the [repository](https://github.com/openjdk/jfx) and clone it to your local machine. See
the [GitHub help page](https://help.github.com/articles/fork-a-repo) for help.

### Before submitting a pull request

If you are a first time contributor to OpenJFX, welcome! Please do the following before you submit your first pull request:

* Sign the Contributor Agreement

    In order for us to evaluate your contribution, you need to sign the [Oracle Contributor Agreement](https://www.oracle.com/technetwork/community/oca-486395.html) (OCA). We are not asking you to give up your copyright, but to give us the right to distribute your code without restriction. By doing this you assert that the code you contribute is *yours* to contribute, and not third-party code that you do not own. We ask this of all contributors in order to assure our users of the origin and continuing existence of the code. You only need to sign the OCA once.

* Read the code review policies

    Please read the entire section below on how to submit a pull request, as well as the [OpenJFX Code Review Policies](https://wiki.openjdk.java.net/display/OpenJFX/Code+Reviews). If this is a feature request, please note the additional requirements and expectations in the [New features / API additions](https://wiki.openjdk.java.net/display/OpenJFX/Code+Reviews#CodeReviews-NewFeaturesC.Newfeatures/APIadditions.) section of the Code Review Policies doc.

* File a bug in JBS for every pull request

    A [JBS](https://bugs.openjdk.java.net) bug ID is needed for every
    pull request. If there isn't already a bug filed in JBS, then please
    file one at [bugreport.java.com](https://bugreport.java.com/).
    A developer with an active OpenJDK ID can file a bug directly in JBS.

TIP: A GitHub pull request (PR) should not be the first time we hear about your proposed change to OpenJFX. Unless clearly identified as experimental or work-in-progress (WIP), we will usually close a pull request that isn't associated with an existing bug report. Reading the policies below will help you in getting your change approved.

### Submitting your changes via a pull request

Once your changes and tests are ready to submit for review:

1. Test your changes

    Run the test suite to make sure that nothing is broken.

2. Rebase your changes

    Update your local repository with the most recent code from the main [repository]((https://github.com/openjdk/jfx)), and rebase your branch on top of the latest `master` branch. We prefer your initial changes to be squashed into a single commit. See the [GitHub help page](https://help.github.com/articles/about-git-rebase/) for help. Later, if we ask you to make changes, add them as separate commits. This makes them easier to review.

3. Submit a pull request

    Push your local changes to your forked copy of the repository and
    [submit a pull request](https://help.github.com/articles/using-pull-requests).
    The title of the pull request must start with the 7-digit JBS bug id
    (without the `JDK-` prefix), followed by a colon (`:`), then a space,
    and finally the bug title as taken from JBS. You should include
    additional details about your change in the Description of the pull
    request. For example, the following is a valid pull request title:

    ```
    8231326: Update README and CONTRIBUTING docs for Skara
    ```

    The Skara bot will then run `jcheck` on the server to verify the format
    of the PR title and check for whitespace errors. Once that passes,
    it will automatically send a Request For Review (RFR) email to the
    [openjfx-dev](mailto:openjfx-dev@openjdk.java.net) mailing list.
    See the
    [Skara project page](https://github.com/openjdk/skara#openjdk-project-skara)
    for information on `jcheck` and other Skara tools.

    TIP: prefix the pull request title with `WIP:` if you aren't yet
    ready for it to be reviewed. The Skara bot will not send an RFR
    email unless the title starts with a 7-digit bug ID.

    Please cross-link the JBS Issue and the pull request. A link to the
    JBS issue can be added as part of the pull request's Description. A
    link to the PR, can be added as an issue link in the JBS bug. If
    you don't have direct JBS access, one of the Project Committers or
    Authors will do this for you.

    Please adhere to the general guideline that you should never force push
    to a publicly shared branch. Once you have opened your pull request, you
    should consider your branch publicly shared. Instead of force pushing
    you can just add incremental commits; this is generally easier on your
    reviewers. If you need to pick up changes from `master`, you can merge
    `master` into your branch. A reviewer might ask you to rebase a
    long-running pull request in which case force pushing is okay for that
    request. Note that squashing at the end of the review process should
    also not be done. The Skara bot will squash your commits into a
    single commit, and rebase it onto the target branch when the pull
    request is integrated.

4. Code review

    All pull requests _must_ be reviewed according to the
    [OpenJFX Code Review Policies](https://wiki.openjdk.java.net/display/OpenJFX/Code+Reviews).
    It is the responsibility of the Reviewer(s) and the Committer who
    will integrate the change to ensure that the code review policies
    are followed, and that all concerns have been addressed.

    Discussion and review of the pull request can happen either by adding
    a comment to the PR itself, or by replying to the mailing list "RFR"
    thread. The Skara bot will cross-forward between them.
    To approve a pull request, a reviewer must do that in the PR itself.
    See the following
    [GitHub help page](https://help.github.com/en/articles/reviewing-proposed-changes-in-a-pull-request)
    for help on reviewing a pull request.

    If any changes
    are needed, you would push additional commits to the branch
    from which you made the pull request.

    The code review continues until there are no unaddressed concerns, and
    at least the minimum number of reviewers have approved the PR -- which
    is one for low-impact bug fixes and two for enhancements or high-impact
    bug fixes.

    NOTE: while the Skara tooling will indicate that the PR is
    ready to integrate once the first reviewer with a "Reviewer" role
    in the project has approved it, this may or may not be sufficient
    depending on the type of fix. For example, you must wait for a second
    approval for enhancements or high-impact bug fixes.

5. Integrate the pull request

    Once the review has completed as described above, you can integrate
    the PR.

    A. Verify the commit message. The Skara tooling adds a comment with
    the commit message that will be used. You can add a summary to the
    commit message with the `/summary` command. You can add additional
    contributors with the `/contributor` command. Commands are issued
    by adding a comment to the PR that starts with a slash `/` character.

    B. Issue the `/integrate` command. If you have the "Committer" role
    (or higher) in the Project, then the Skara bot will merge the change
    with no further action on your part. If you are not a Committer,
    then you must get a Committer to sponsor your change. This is often
    one of the reviewers who reviewed your PR, but it need not be. The
    sponsor will issue the `/sponsor` command after you issue `/integrate`
    once they are satisfied that the review criteria have been met.

6. Resolve the JBS bug as "Fixed"

    There is currently no automation for resolving JBS bugs, although
    a future Skara improvement will automate this. Until then,
    the Committer who integrated or sponsored the fix is responsible for
    resolving the JBS issue. You do this with the "Resolve" action in JBS,
    selecting "Fixed" as the resolution. You also need to add the commit
    notification message (minus the list of modified files) as a comment.
    This includes the URL of the commit. For example:

    ```
    Changeset: 1de25a49
    Author:    Kevin Rushforth <kcr@openjdk.org>
    Date:      2019-09-23 08:15:36 +7000
    URL:       https://git.openjdk.java.net/jfx/commit/1de25a49

    8231126: libxslt.md has incorrect version string

    Reviewed-by: ghb
    ```


Contributing to the OpenJFX codebase
------------------------------------------

JDK 11 (at a minimum) is required to build OpenJFX. You must have a JDK 11 installation
with the environment variable `JAVA_HOME` referencing the path to Java home for
your JDK 11 installation. By default, tests use the same runtime as `JAVA_HOME`.
Currently OpenJFX builds are running on JDK 11 (recommended) and JDK 12.

It is possible to develop in any major Java IDE (Eclipse, IntelliJ, NetBeans). IDEs can automatically configure projects based on Gradle setup.

The following formatting rules are enforced for source code files by
`git jcheck`, which is run by the Skara bot:

* Use Unix-style (LF) line endings not DOS-style (CRLF)
* Do not use TAB characters (exception: Makefiles can have TABS)
* No trailing spaces
* No files with execute permission

Please also follow these formatting guidelines:

* Java indent is 4 spaces
* Line width is no more than 120 characters
* The rest is left to Java coding standards
* Disable &ldquo;auto-format on save&rdquo; to prevent unnecessary format changes. This makes reviews much harder as it generates unnecessary formatting changes. If your IDE supports formatting only modified chunks that is fine to do.
* Wildcard imports (`import foo.bar.baz.*`) are forbidden and may cause the build to fail. Please attempt to tame your IDE so it doesn't make them and please send a PR against this document with instructions for your IDE if it doesn't contain them.
* Don't worry too much about import order. Try not to change it but don't worry about fighting your IDE to stop it from doing so.

OpenJFX uses Gradle for its build. Before submitting your changes, run the test suite to make sure that nothing is broken, with:

```sh
bash ./gradlew all test
```

If you are changing anything that might possibly affect rendering, you should run a full test with robot enabled:

```sh
bash ./gradlew -PFULL_TEST=true -PUSE_ROBOT=true all test
```

Even more documentation on OpenJFX projects and its build system can be found on the
[OpenJFX Wiki](https://wiki.openjdk.java.net/display/OpenJFX/).