# vim_g3-autonbsp

Neovim plugin pro automatické vkládání nedělitelných mezer podle českých typografických pravidel.

## Struktura

```text
vim_g3-autonbsp/
├─ README.md
└─ lua/
   └─ g3_autonbsp/
      └─ init.lua
```

## LazyVim

Do svého LazyVim configu přidej plugin spec:

```lua
return {
  {
    "G3rz/vim_g3-autonbsp",
    config = function()
      require("g3_autonbsp").setup()
    end,
  },
}
```

## Použití

- `<F7>` vloží hard space
- `<F6>` vloží `&nbsp;`
- `:G3Autonbsp` vloží hard space
- `:G3Autonbsp &nbsp;`
- ve visual režimu keymapy upraví celé řádky označeného textu
- command podporuje range, např. `:'<,'>G3Autonbsp &nbsp;`
- chrání HTML tagy, shortcody a celé bloky `script`, `style`, `pre` a `code`

## Konfigurace

```lua
require("g3_autonbsp").setup({
  command = "G3Autonbsp",
  keymaps = {
    hard = "<F7>",
    html = "<F6>",
  },
})
```

Keymapy nebo command lze vypnout:

```lua
require("g3_autonbsp").setup({
  command = false,
  keymaps = false,
})
```
