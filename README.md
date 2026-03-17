# vim_g3-autonbsp

Neovim plugin pro automaticke vkladani nedelitelnych mezer podle ceskych typografickych pravidel.

## Struktura

```text
vim_g3-autonbsp/
├─ README.md
└─ lua/
   └─ g3_autonbsp/
      └─ init.lua
```

## LazyVim

Do sveho LazyVim configu pridej plugin spec:

```lua
return {
  {
    "USERNAME/vim_g3-autonbsp",
    config = function()
      require("g3_autonbsp").setup()
    end,
  },
}
```

## Pouziti

- `<F7>` vlozi hard space
- `<F6>` vlozi `&nbsp;`
- `:G3Autonbsp`
- `:G3Autonbsp &nbsp;`

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
