# NeuRIS - Importer for migrated norms into the norms database tables

[![Pipeline](https://github.com/digitalservicebund/ris-norms-migration-import/actions/workflows/pipeline.yml/badge.svg)](https://github.com/digitalservicebund/ris-norms-migration-import/actions/workflows/pipeline.yml)
[![Scan](https://github.com/digitalservicebund/ris-norms-migration-import/actions/workflows/scan.yml/badge.svg)](https://github.com/digitalservicebund/ris-norms-migration-import/actions/workflows/scan.yml)
[![Secrets Check](https://github.com/digitalservicebund/ris-norms-migration-import/actions/workflows/secrets-check.yml/badge.svg)](https://github.com/digitalservicebund/ris-norms-migration-import/actions/workflows/secrets-check.yml)

Importer for mirgated norms from the migration database tables into the norms database tables

## Prerequisites

Docker for building + running the containerized application:

```bash
brew install --cask docker # or just `brew install docker` if you don't want the Desktop app
```

For the provided Git hooks you will need:

```bash
brew install lefthook node talisman
```

## Git hooks

The repo contains a [Lefthook](https://github.com/evilmartians/lefthook/blob/master/docs/full_guide.md) configuration,
providing a Git hooks setup out of the box.

**To install these hooks, run:**

```bash
./run.sh init
```

The hooks are supposed to help you to:

- commit properly formatted source code only (and not break the build otherwise)
- write [conventional commit messages](https://chris.beams.io/posts/git-commit/)
- not accidentally push [secrets and sensitive information](https://thoughtworks.github.io/talisman/)

## Running locally
Prerequisites:
- running [`ris-norms` application](https://github.com/digitalservicebund/ris-norms)
- ran [`ris-norms-migration`](https://github.com/digitalservicebund/ris-norms-migration)
- both applications use the same database

Create a `.env` file, based on `.env.example`, load it into your shell, and then run the script:
```bash
cd src/
./import_from_migration.sh
```

## Container image

Container images running the application are automatically published by the pipeline to
the [GitHub Packages Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

**To run the latest published image:**

```bash
docker run "ghcr.io/digitalservicebund/ris-norms-migration-import:$(git log -1 origin/main --format='%H')"
```

Container images in the registry are [signed with keyless signatures](https://github.com/sigstore/cosign/blob/main/KEYLESS.md).

**To verify an image**:

```bash
cosign verify "ghcr.io/digitalservicebund/ris-norms-migration-import:$(git log -1 origin/main --format='%H')" --certificate-identity="https://github.com/digitalservicebund/ris-norms-migration-import/.github/workflows/pipeline.yml@refs/heads/main" --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

If you need to push a new container image to the registry manually there are two ways to do this:

**Via built-in Gradle task:**

```bash
IMAGE_VERSION="$(git log -1 --format='%H')"
docker build -t ghcr.io/digitalservicebund/ris-norms-migration-import:$IMAGE_VERSION .
echo [github-token] | docker login ghcr.io -u [github-user] --password-stdin
docker push ghcr.io/digitalservicebund/ris-norms-migration-import:$IMAGE_VERSION
```

**Note:** Make sure you're using a GitHub token with the necessary `write:packages` scope for this to work.

**Using Docker:**

```bash
echo [github-token] | docker login ghcr.io -u [github-user] --password-stdin
docker push "ghcr.io/digitalservicebund/ris-norms-migration-import:$(git log -1 --format='%H')"
```

**Note:** Make sure you're using a GitHub token with the necessary `write:packages` scope for this to work.

## Vulnerability Scanning

Scanning container images for vulnerabilities is performed with [Trivy](https://github.com/aquasecurity/trivy)
as part of the pipeline's `build` job, as well as each night for the latest published image in the container
repository.

**To run a scan locally:**

Install Trivy:

```bash
brew install aquasecurity/trivy/trivy
```

```bash
docker build -t ghcr.io/digitalservicebund/ris-norms-migration-import:latest .
trivy image --severity HIGH,CRITICAL ghcr.io/digitalservicebund/ris-norms-migration-import:latest
```

As part of the automated vulnerability scanning we are generating a Cosign vulnerability scan record using Trivy,
and then use Cosign to attach an attestation of it to the container image, again
[signed with keyless signatures](https://github.com/sigstore/cosign/blob/main/KEYLESS.md) similar to signing the
container image itself. Using a policy engine in a cluster the vulnerability scan can be verified and for instance
running a container rejected if a scan is not current.

## Slack notifications

Opt in to CI posting notifications for failing jobs to a particular Slack channel by setting a repository secret
with the name `SLACK_WEBHOOK_URL`, containing a url for [Incoming Webhooks](https://api.slack.com/messaging/webhooks).

## Contributing

🇬🇧
Everyone is welcome to contribute the development of the _ris-norms-migration-import_. You can contribute by opening pull request,
providing documentation or answering questions or giving feedback. Please always follow the guidelines and our
[Code of Conduct](CODE_OF_CONDUCT.md).

🇩🇪
Jede:r ist herzlich eingeladen, die Entwicklung der _ris-norms-migration-import_ mitzugestalten. Du kannst einen Beitrag leisten,
indem du Pull-Requests eröffnest, die Dokumentation erweiterst, Fragen beantwortest oder Feedback gibst.
Bitte befolge immer die Richtlinien und unseren [Verhaltenskodex](CODE_OF_CONDUCT_DE.md).

## Code Contributions

🇬🇧
Open a pull request with your changes and it will be reviewed by someone from the team. When you submit a pull request, you declare that you have the right to license your contribution to DigitalService and the community. By submitting the patch, you agree that your contributions are licensed under the [GPLv3 license](./LICENSE).

Please make sure that your changes have been tested before submitting a pull request.

🇩🇪
Nach dem Erstellen eines Pull Requests wird dieser von einer Person aus dem Team überprüft. Wenn du einen Pull Request einreichst, erklärst du dich damit einverstanden, deinen Beitrag an den DigitalService und die Community zu lizenzieren. Durch das Einreichen des Patches erklärst du dich damit einverstanden, dass deine Beiträge unter der [GPLv3-Lizenz](./LICENSE) lizenziert sind.

Bitte stelle sicher, dass deine Änderungen getestet wurden, bevor du einen Pull Request sendest.
