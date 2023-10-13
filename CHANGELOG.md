# Changelog

## [1.8.2](https://github.com/folke/edgy.nvim/compare/v1.8.1...v1.8.2) (2023-10-13)


### Bug Fixes

* **editor:** use buf number to use as new main. ([e75283c](https://github.com/folke/edgy.nvim/commit/e75283cde36056e756f535740085d4a721786721))
* use eval_statusline to determine title width ([#46](https://github.com/folke/edgy.nvim/issues/46)) ([f399e8f](https://github.com/folke/edgy.nvim/commit/f399e8f79a56678788cbc0cb4a4b02bed7adce42))

## [1.8.1](https://github.com/folke/edgy.nvim/compare/v1.8.0...v1.8.1) (2023-09-30)


### Bug Fixes

* high CPU usage with invalid config (fixes [#49](https://github.com/folke/edgy.nvim/issues/49)) ([#50](https://github.com/folke/edgy.nvim/issues/50)) ([ee41d71](https://github.com/folke/edgy.nvim/commit/ee41d71429315882a75a34a165309c360cb956d7))

## [1.8.0](https://github.com/folke/edgy.nvim/compare/v1.7.0...v1.8.0) (2023-07-25)


### Features

* allow configuring window size with functions ([#39](https://github.com/folke/edgy.nvim/issues/39)) ([7506f83](https://github.com/folke/edgy.nvim/commit/7506f830de2b35cc13f940d9d74d43a2db50fe99))

## [1.7.0](https://github.com/folke/edgy.nvim/compare/v1.6.1...v1.7.0) (2023-06-30)


### Features

* **option:** allow closing edgy when all windows are hidden ([#30](https://github.com/folke/edgy.nvim/issues/30)) ([c925031](https://github.com/folke/edgy.nvim/commit/c9250315f26784bd890373e0a87e4bbacb106d70))

## [1.6.1](https://github.com/folke/edgy.nvim/compare/v1.6.0...v1.6.1) (2023-06-21)


### Bug Fixes

* return when no real windows found ([0ffa543](https://github.com/folke/edgy.nvim/commit/0ffa543df455a442ed0dac9f307557e0ff579118))

## [1.6.0](https://github.com/folke/edgy.nvim/compare/v1.5.0...v1.6.0) (2023-06-16)


### Features

* you can now resize edgy windows. See the readme for more details ([8aa7a0e](https://github.com/folke/edgy.nvim/commit/8aa7a0e1f74cb7fdb7becb76d7ed4526d28f757b))


### Bug Fixes

* **animate:** don't animate terminal windows since it conflicts with reflow and can cause segfaults. Fixes [#23](https://github.com/folke/edgy.nvim/issues/23) ([408d053](https://github.com/folke/edgy.nvim/commit/408d05303853092276b1c69a73bfbde246636e2a))

## [1.5.0](https://github.com/folke/edgy.nvim/compare/v1.4.0...v1.5.0) (2023-06-09)


### Features

* **commands:** added `require("edgy").toggle()` ([280cf44](https://github.com/folke/edgy.nvim/commit/280cf444c076e8e849fbcfea5eac2569b6dfeb50))


### Bug Fixes

* **view:** fixed opening state of pinned views ([fa28a44](https://github.com/folke/edgy.nvim/commit/fa28a44f901e0ab5d51fff317565dd942ed36040))
* **view:** open pinned when edgebar is active ([f4f2d0f](https://github.com/folke/edgy.nvim/commit/f4f2d0fdaf73f282b38527cd8aac04cda33bcecf))

## [1.4.0](https://github.com/folke/edgy.nvim/compare/v1.3.0...v1.4.0) (2023-06-08)


### Features

* added edgy.open to open all pinned views in a given sidebar (or all) ([0f40452](https://github.com/folke/edgy.nvim/commit/0f40452201f9f5d2b0f2528c1657c21ecbb370df))


### Bug Fixes

* **windows:** add winhl instead of overwriting. Can also be set to "" to prevent edge changing winhl. Fixes [#15](https://github.com/folke/edgy.nvim/issues/15) ([779fdd8](https://github.com/folke/edgy.nvim/commit/779fdd85d930e75579870857a4d6abe9427abaad))

## [1.3.0](https://github.com/folke/edgy.nvim/compare/v1.2.0...v1.3.0) (2023-06-07)


### Features

* optionally exit Neovim when the last main window was closed ([45a6322](https://github.com/folke/edgy.nvim/commit/45a6322f444e7b6c23f0228e60b6495ca7cfc179))


### Bug Fixes

* **layout:** always use rightbelow for splitmove. Fixes [#14](https://github.com/folke/edgy.nvim/issues/14) ([d0d3e22](https://github.com/folke/edgy.nvim/commit/d0d3e22bfdfaa551e7247659a875ae6f90fde0db))
* **layout:** take laststatus=1 or 2 into account when calculating collpased height ([df1abc9](https://github.com/folke/edgy.nvim/commit/df1abc98db91e5aed486ee2a542b1747ddea50c8))
* much better view state management. Fixes issue with splitkeep and jumping to loc ([482e127](https://github.com/folke/edgy.nvim/commit/482e127dde1a0365c3b2b78926ade92cd36bf564))

## [1.2.0](https://github.com/folke/edgy.nvim/compare/v1.1.0...v1.2.0) (2023-06-06)


### Features

* added `require("edgy").select()` to jump to a edgy window ([7572ae2](https://github.com/folke/edgy.nvim/commit/7572ae2b680df81646a1c764fb2625f76c817fae))
* added keymaps to quickly jump between edgebar windows ([e1469b1](https://github.com/folke/edgy.nvim/commit/e1469b179d642840e83c590c3dc52e61342a60eb))
* expose some commands on the main edgy module ([af8df65](https://github.com/folke/edgy.nvim/commit/af8df6581f4915b4ef62f0436aacdf8ff2cc890a))

## [1.1.0](https://github.com/folke/edgy.nvim/compare/v1.0.0...v1.1.0) (2023-06-05)


### Features

* allow disabling edgy for a buf/win with var edgy_disable ([b1e87ab](https://github.com/folke/edgy.nvim/commit/b1e87abecb69eb6fd96b6f55a4905b8928104c09))
* **animate:** show a spinner when loading a pinned view ([8dc7aee](https://github.com/folke/edgy.nvim/commit/8dc7aeeca847b03949f19454df926e1c4613e911))
* set edgy filetype ([e345756](https://github.com/folke/edgy.nvim/commit/e3457565fc7a4cd4ab75b74ee2da1ed8a35202aa))


### Bug Fixes

* **animate:** better save/restore of window views ([9acf7cc](https://github.com/folke/edgy.nvim/commit/9acf7cc9c63c499bcd115daf70b61af0a17171bc))
* **animate:** restore leftcol during animate ([9eededc](https://github.com/folke/edgy.nvim/commit/9eededc45cdbff2b1a5f709b26832eca80b4a5c1))
* don't set winbar when false ([89d0e9c](https://github.com/folke/edgy.nvim/commit/89d0e9c05fd439b39f378c7f03f748fe6c36ab5a))
* **layout:** always do instant resize when views were added or deleted ([483861d](https://github.com/folke/edgy.nvim/commit/483861d0a3cfbedcddec0ff0a8fb83f62be716a5))

## 1.0.0 (2023-06-05)


### Features

* added buffer-local keymaps ([18635d8](https://github.com/folke/edgy.nvim/commit/18635d8854b02b0d263aa758516f58e7052dd468))
* added close methods ([e4ca3ab](https://github.com/folke/edgy.nvim/commit/e4ca3ab70275472b685ddaa91fd627fb44e01750))
* added pinned views ([07a1b6d](https://github.com/folke/edgy.nvim/commit/07a1b6d7b7d5ca0cd215426eca8558b6a535758c))
* added sidebar as a prop of view ([4883d03](https://github.com/folke/edgy.nvim/commit/4883d0356e0d6d25f74a51951cf8853f0caec56e))
* added small util module ([30a13af](https://github.com/folke/edgy.nvim/commit/30a13afa34bfdda1346365adfd4dca1cc4b09da3))
* added support for floating windows ([8fb1105](https://github.com/folke/edgy.nvim/commit/8fb1105a6987eeb0984d6b89556e0a14a83adf8f))
* animations ([b4707ad](https://github.com/folke/edgy.nvim/commit/b4707ad4dc3326aabb313b624d0f2ff6b247ca07))
* better handling of main windows ([ec85a1f](https://github.com/folke/edgy.nvim/commit/ec85a1f8435c4f0dff5419884f5a1cd088eba303))
* collapsing vertical views collpse to window title ([8b9b76d](https://github.com/folke/edgy.nvim/commit/8b9b76dc1a96f0c9a04a0091e2b2017aab698085))
* **config:** made all hl groups and view options configurable ([f0a6ab3](https://github.com/folke/edgy.nvim/commit/f0a6ab36f8dcb076aae0b52ac1021fab2c5608d3))
* expand view when needed when buffer becomes the current ([30b90de](https://github.com/folke/edgy.nvim/commit/30b90de37efde0a5ac2e95bdde837cdbfea59d76))
* initial commit 🎉 ([8ccc3b0](https://github.com/folke/edgy.nvim/commit/8ccc3b02f1d957917592a66146301fcd080ad3fe))
* **layout:** added some debugging tools ([f7bfbb4](https://github.com/folke/edgy.nvim/commit/f7bfbb4ee5f8567e781a539ab0a0e13781eb080d))
* retry layout when needed ([2e7f2c0](https://github.com/folke/edgy.nvim/commit/2e7f2c01f68b68cf69d27bd66f2e120081a1e7c8))
* **sidebar:** added sidebar:close() ([94de9c6](https://github.com/folke/edgy.nvim/commit/94de9c66631618e65bcb9a772f7079b7a5ab1fa9))
* simplified config ([f48b78e](https://github.com/folke/edgy.nvim/commit/f48b78e52de788f97f7fdba57098a3ed2a0ef53d))
* use ctrl-q to hide a window in the sidebar ([5974a31](https://github.com/folke/edgy.nvim/commit/5974a312166c352acbc6398d038bf924510d65fa))
* **util:** added debounce ([c0ae068](https://github.com/folke/edgy.nvim/commit/c0ae06840139c656b0f83ef4d990226629ad5a0d))
* **util:** added with_retry and noautocmd ([c9e5236](https://github.com/folke/edgy.nvim/commit/c9e523669850a02c548ea8b6e39042ec06c85b39))
* **view:** added optional filtering of view windows ([7199063](https://github.com/folke/edgy.nvim/commit/719906302c5378857eba333bb20a71b30377bdbf))


### Bug Fixes

* disable splitkeep when needed in nvim_win_set_height ([530f982](https://github.com/folke/edgy.nvim/commit/530f98219560c29994bdff2f213222c75c9a5400))
* **hacks:** check that win is valid ([aef29eb](https://github.com/folke/edgy.nvim/commit/aef29eb6164e3f6a644cdd7194fb0218a5ccaf12))
* **hacks:** disable splitkeep for now when resizing. See upstream PR ([eef534c](https://github.com/folke/edgy.nvim/commit/eef534ccdf5663eead994c7d46dc3259cbd74cb3))
* **layout:** also check that sidebar window sizes are equal in needs_layout ([1b09518](https://github.com/folke/edgy.nvim/commit/1b09518d8a7d52ff03882b7a3c3b12b51c33ad92))
* **layout:** fixed calculation of long edge ([0fc9c80](https://github.com/folke/edgy.nvim/commit/0fc9c80f1729f6ddb93af449f47715ad7d3471ee))
* **layout:** improved viewstate handling ([6448c8d](https://github.com/folke/edgy.nvim/commit/6448c8de3a7b04e0e94322bb550a574d5ea9a892))
* **layout:** update layout on WinNew and WinResized as well ([40077a7](https://github.com/folke/edgy.nvim/commit/40077a7cec0600e98f4a077b4c5a3d66886653e2))
* **layout:** use debounce for resizes ([640b98b](https://github.com/folke/edgy.nvim/commit/640b98b35483a0aac014df1c1c154089384848c4))
* **layout:** weird one-off bug on horizontal sidebars ([875853a](https://github.com/folke/edgy.nvim/commit/875853a24e448e5109faa64daecab2c84080d0e8))
* make sure to have at least one window open ([6ae8d23](https://github.com/folke/edgy.nvim/commit/6ae8d23e3e5f567d2d0bd6eb7378e5851a2186de))
* move state save/restore to updater ([6c482c1](https://github.com/folke/edgy.nvim/commit/6c482c142bdd3dffc2e457f707cb34b71905539b))
* no longer seems needed to change splitkeep ([62d1132](https://github.com/folke/edgy.nvim/commit/62d11321aaa649d5cfea2f52339afc3c39aa0b80))
* no need to store last window ([2d080f8](https://github.com/folke/edgy.nvim/commit/2d080f808c6e262387869e9eccc013b605d72344))
* only check for windows on the current tabpage ([794ab42](https://github.com/folke/edgy.nvim/commit/794ab423120dcbe14f63c3826e1af886c2b47782))
* properly deal with winheight=1 and winbar ([fb30fcc](https://github.com/folke/edgy.nvim/commit/fb30fcc7c4159514143d6435fc25719ff017412f))
* set winfixwidth to prevent windows.nvim and other plugins to change the width ([933b235](https://github.com/folke/edgy.nvim/commit/933b235eccaac43c18938a464705dd8dec31c5eb))
* **sidebar:** resize when no window is open ([83621f5](https://github.com/folke/edgy.nvim/commit/83621f5817b023e70d585ccabb5c105b6922b6bc))
* **sidebar:** use Util.noautocmd for sidebar.close ([0eb178d](https://github.com/folke/edgy.nvim/commit/0eb178df7150d51ac9c64d6b529b688b1dbbf82e))
* when collapsing a window, jump to a non sidebar window ([156d69e](https://github.com/folke/edgy.nvim/commit/156d69e16077a7f92b87addb2c455bde2873ebaf))
* **window:** better handling of window hiding ([6f093eb](https://github.com/folke/edgy.nvim/commit/6f093eba91ce42edfc2b9dfa7422a7d2b495ffa3))
* **window:** dont try opening a pinned window more than once ([3cc5be8](https://github.com/folke/edgy.nvim/commit/3cc5be87751e72b51db8c5825c4712d7800e857a))
* **window:** go to main should skip floating windows ([993b576](https://github.com/folke/edgy.nvim/commit/993b576cf44dcfe92e4d2ffc85515abf427c33c1))
* **window:** resize sidebar only when open/close windows ([a35bab7](https://github.com/folke/edgy.nvim/commit/a35bab74b9f3aaab5aaacc2c20497bc4512c190f))
* winsaveview and winresetview ([82fcdca](https://github.com/folke/edgy.nvim/commit/82fcdca453793b33d197ecbd766f52c0ea7a25eb))


### Performance Improvements

* only resize when sidebar has windows ([fc7b6da](https://github.com/folke/edgy.nvim/commit/fc7b6daf8f2ec18c12b916c5639b917b45c6c325))
* reduced a lot of flickering in comination with mini.animate ([495f36a](https://github.com/folke/edgy.nvim/commit/495f36ae6db677bb9539e2cc3fc2ab79358cc058))
* **window:** only update height/width when needed ([004a097](https://github.com/folke/edgy.nvim/commit/004a09763ed8b2fe45f3752e8275434a6756e6e9))
