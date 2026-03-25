# RuntimeGems for PicoRuby

## Usage

Go to https://picoruby.org/runtimegems

## Contributing

Fork this repository, add a new `[gem name].yaml` file that contains your gem's info, and send the PR.

- `[gem name]` must be unique
- RuntimeGem must contain only Ruby implementation. C implementation is never going to be handled

### Example

All the items other than `tags` and `path` are mandatory. When `path` is blank, `mrbgem.rake` and `mrblib/` are supposed to locate at the top directory.

```yaml
name: picoruby-aht25
repo: https://github.com/picoruby/picoruby
path: mrbgems/picoruby-aht25/
ref: master
description": AHT25 temperature and humidity sensor library for PicoRuby.
tags:
  - AHT25
  - temperature
  - humidity
  - I2C
```

## Disclaimer

All content provided through this repository is offered “as is”, without any warranties or guarantees of any kind, either express or implied. The maintainers do not warrant the accuracy, completeness, reliability, or suitability of any content.

By using this system, you acknowledge and agree that the maintainers of this repository shall not be held liable for any direct, indirect, incidental, consequential, or other damages arising from or related to the use of, or inability to use, any content provided through this repository.

Use all content at your own risk.
