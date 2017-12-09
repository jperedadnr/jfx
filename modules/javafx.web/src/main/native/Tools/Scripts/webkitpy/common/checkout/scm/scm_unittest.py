# Copyright (C) 2009, 2016 Apple Inc. All rights reserved.
from webkitpy.common.net.bugzilla import Attachment  # FIXME: This should not be needed

    process.communicate()  # ignore output
        self.dev_null = open(os.devnull, "w")  # Used to make our Popen calls quiet.
        input_process = subprocess.Popen(['echo', 'foo\nbar'], stdout=subprocess.PIPE, stderr=self.dev_null)  # grep shows usage and calls exit(2) when called w/o arguments.
        git_failure_message = "Merge conflict during commit: Your file or directory 'WebCore/ChangeLog' is probably out-of-date: resource out of date; try updating at /usr/local/libexec/git-core//git-svn line 469"
        svn_failure_message = """svn: Commit failed (details follow):
        self.assertItemsEqual(self.scm.revisions_changing_file("non_existent_file"), [])
        write_into_file_at_path(create_patch_path, '#!/bin/sh\necho $PWD')  # We could pass -n to prevent the \n, but not all echo accept -n.
        actual_patch_contents = scm.create_patch()
        expected_patch_contents = """Index: test_dir2/test_file2
===================================================================
--- test_dir2/test_file2\t(nonexistent)
+++ test_dir2/test_file2\t(working copy)
@@ -0,0 +1 @@\n+test content
\\ No newline at end of file
"""
        self.assertEqual(expected_patch_contents, actual_patch_contents)
    def test_native_revision(self):
        self.assertEqual(self.scm.head_svn_revision(), self.scm.native_revision('.'))
        self.assertEqual(self.scm.native_revision('.'), '5')


    def test_native_revision(self):
        scm = self.tracking_scm
        command = ['git', '-C', scm.checkout_root, 'rev-parse', 'HEAD']
        self.assertEqual(scm.native_revision(scm.checkout_root), run_command(command).strip())

        self.assertRaises(ScriptError, run_silent, ['git', 'svn', '--quiet', 'rebase'])  # Will fail due to a conflict leaving us mid-rebase.
    def test_native_revision(self):
        command = ['git', '-C', self.git_checkout_path, 'rev-parse', 'HEAD']
        self.assertEqual(self.scm.native_revision(self.git_checkout_path), run_command(command).strip())


    def test_timestamp_of_native_revision(self):
        scm = self.make_scm()
        scm.find_checkout_root = lambda path: ''
        scm._run_git = lambda args: '1360310749'
        self.assertEqual(scm.timestamp_of_native_revision('some-path', '1a1c3b08814bc2a8c15b0f6db63cdce68f2aaa7a'), '2013-02-08T08:05:49Z')

        scm._run_git = lambda args: '1360279923'
        self.assertEqual(scm.timestamp_of_native_revision('some-path', '1a1c3b08814bc2a8c15b0f6db63cdce68f2aaa7a'), '2013-02-07T23:32:03Z')

        scm._run_git = lambda args: '1360317321'
        self.assertEqual(scm.timestamp_of_native_revision('some-path', '1a1c3b08814bc2a8c15b0f6db63cdce68f2aaa7a'), '2013-02-08T09:55:21Z')