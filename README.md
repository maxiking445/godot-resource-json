# ResourceJSON

<p align="center">
  <img src="https://img.shields.io/github/license/maxiking445/godot-resource-json" alt="License">
  <img src="https://img.shields.io/github/v/release/maxiking445/godot-resource-json" alt="Latest Release">
</p>

ResourceJSON is a lightweight Godot addon for converting Resources to JSON
and restoring them from JSON. Its goal is to make Resources easier to store,
exchange, inspect, and process.

## Development setup

The test dependency GUT is not committed to this repository and is not part of
the distributed addon. Install it locally with:

```sh
./install_GUT.sh
```

The script installs GUT into `addons/gut/`. This directory is ignored by Git.
By default, the branch compatible with Godot 4.7 is used. To install a specific
GUT tag or commit instead, set `GUT_REF`, for example:

```sh
GUT_REF=v9.6.0 ./install_GUT.sh
```

This command installs GUT and then runs all configured tests. The lower-level
installer without the automatic test run is located at
`addons/gut/install_gut.sh`.
