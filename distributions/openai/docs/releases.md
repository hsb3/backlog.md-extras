# Verifying a release

Each release attaches `backlog-extras-claude-<version>.zip`,
`backlog-extras-openai-<version>.zip` and `SHA256SUMS`. Download all three into
one directory, then run:

```sh
sha256sum -c SHA256SUMS
for archive in backlog-extras-*.zip; do
  gh attestation verify "$archive" --repo hsb3/backlog.md-extras \
    --signer-workflow hsb3/backlog.md-extras/.github/workflows/release.yml \
    --source-ref refs/heads/main || exit 1
done
```

The attestation proves which workflow built the archive. It does not prove host
support or that the code is safe. The release notes name the tagged source commit.
