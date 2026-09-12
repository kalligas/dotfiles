"""Safety checks: python3 knowledge-base/test_kb.py."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
HELPER = REPO / "home/.local/bin/kb"


class VaultSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kb-test-")
        self.root = Path(self.temp.name).resolve()
        self.vault = self.root / "Vault with spaces"
        self.env = dict(os.environ, KB_TEMPLATE_DIR=str(REPO / "knowledge-base/vault-template"))
        self.env.pop("KB_VAULT_PATH", None)

    def tearDown(self):
        self.temp.cleanup()

    def kb(self, command, path=None):
        args = ["bash", str(HELPER), command]
        if path is not None:
            args.append(str(path))
        return subprocess.run(args, env=self.env, capture_output=True, text=True)

    def test_no_implicit_vault(self):
        self.assertNotEqual(self.kb("status").returncode, 0)

    def test_init_and_existing_path_preserved(self):
        self.assertEqual(self.kb("init", self.vault).returncode, 0)
        inbox = self.vault / "Inbox.md"
        inbox.write_text("Do not overwrite my capture\n")
        self.assertNotEqual(self.kb("init", self.vault).returncode, 0)
        self.assertEqual(inbox.read_text(), "Do not overwrite my capture\n")

    def test_dangling_symlink_refused(self):
        self.vault.symlink_to(self.root / "missing")
        self.assertNotEqual(self.kb("init", self.vault).returncode, 0)
        self.assertTrue(self.vault.is_symlink())

    def test_nested_repository_refused(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        self.assertNotEqual(self.kb("init", self.vault).returncode, 0)
        self.assertFalse(self.vault.exists())

    def test_agent_requires_baseline(self):
        self.assertEqual(self.kb("init", self.vault).returncode, 0)
        result = self.kb("agent", self.vault)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("baseline", result.stderr)

    def test_diff_includes_new_files_and_preserves_content(self):
        self.assertEqual(self.kb("init", self.vault).returncode, 0)
        note = self.vault / "Unreviewed.md"
        note.write_text("Unreviewed capture\n")
        result = self.kb("diff", self.vault)
        self.assertEqual(result.returncode, 0)
        self.assertIn("Unreviewed.md", result.stdout)
        self.assertEqual(note.read_text(), "Unreviewed capture\n")


if __name__ == "__main__":
    unittest.main()
