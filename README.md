# Squash Docker Tags GitHub Action

A GitHub Action that allows you to "squash" any input tags into a single output tag. Intended to create a multiarch image from multiple single-arch images.

## Quick Start

```yml
...

jobs:
  squash-images:
    runs-on: ubuntu-latest
    steps:
      - name: Login to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.YOUR_REGISTRY }} # Can omit this if just using Docker Hub
          username: ${{ env.REGISTRY_USER }}
          password: ${{ env.REGISTRY_PASS }}
      - name: Squash Tags
        uses: ubergeek77/squash-docker-tags@v1
        with:
          source-tags: |
            example-user/example-image:example-tag-x64
            example-user/example-image:example-tag-arm
            example-user/example-image:example-tag-arm64
          destination-tag: example-user/example-image:example-tag


...
```

## Usage

This one is pretty straightforward. Just supply a list of input tags, and a single output tag. The Action will detect the best Docker tool to use (either `buildx` or `manifest`), merge the input tags for you, and push them to the destination registry.

The example shows a multi-line string for `source-tags`, but you can actually supply the input in a bunch of different ways:

```
source-tags: image1,image2,image3,etc

source-tags: image1 image2 image3 etc

source-tags: |
  image1
  image2
  image3
  etc
```

Use whichever is most readable for you!

## Disclaimer

I made this for myself and decided to make it public. You can use it if you want, too. But, while I have published this, I don't make any security or usage guarantees. This is provided as-is. ***I*** think I did a pretty good job, but I'm biased :)

## Donate

If this Action helped you, and you would like to support me, I have crypto addresses:

- Bitcoin: `bc1qekqn4ek0dkuzp8mau3z5h2y3mz64tj22tuqycg`
- Monero/Ethereum: `0xdAe4F90E4350bcDf5945e6Fe5ceFE4772c3B9c9e`

