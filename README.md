# Configuração NixOS — `nixos`

Configuração em flakes para o desktop de Arthur, usando `nixos-unstable`, KDE
Plasma 6 e o display manager Ly, além de GRUB no caminho UEFI fallback
`EFI/BOOT/BOOTX64.EFI`.

## Antes da instalação

1. Inicialize a mídia do NixOS em modo UEFI.
2. Monte as partições existentes sob `/mnt`, incluindo a ESP em `/mnt/boot`
   ou `/mnt/boot/efi`.
3. Clone este repositório em `/mnt/etc/nixos`.
4. Gere somente a configuração de hardware:

   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config \
     | sudo tee /mnt/etc/nixos/hardware-configuration.nix >/dev/null
   ```

5. Confirme que `hardware-configuration.nix` contém a raiz, a home separada
   (se houver) e a ESP montada sob `/boot`.

O arquivo de hardware não acompanha o repositório porque seus UUIDs somente
existem na instalação real. Se ele for versionado futuramente, confirme antes
que o repositório continuará adequado para exposição pública.

## Validar e instalar

Na raiz do repositório:

```bash
nix flake lock
nix flake check
sudo nixos-install --flake .#nixos
```

Depois da instalação, ainda antes de reiniciar, defina a senha de `arthur`:

```bash
sudo nixos-enter --root /mnt -c 'passwd arthur'
```

O login direto de `root` fica bloqueado; a administração é feita por `sudo`,
sempre com senha.

## Boot

O GRUB é instalado como removível/fallback, sem gravar a NVRAM:

```text
EFI/BOOT/BOOTX64.EFI
```

A configuração detecta a ESP declarada no `hardware-configuration.nix`, desde
que ela seja FAT e esteja montada em `/boot` ou em um caminho abaixo dele.
O menu preserva no máximo dez gerações. O Plasma é o único ambiente gráfico e
o Ly inicia sua sessão diretamente, sem uma especialização intermediária.

As árvores XDG já usadas pelo Plasma continuam em `~/.config/plasma`,
`~/.cache/plasma`, `~/.local/share/plasma` e `~/.local/state/plasma`. Essa
compatibilidade preserva as configurações existentes; uma eventual migração
para os caminhos XDG padrão deve ser feita separadamente.

O Plymouth usa o tema Breeze e oculta os logs durante a inicialização. Para
diagnosticar um boot, edite temporariamente a entrada do GRUB e remova `quiet`
e `splash` da linha do kernel.

## Atualizações

A Action `.github/workflows/update-flake-lock.yml` atualiza, avalia e constrói
o sistema diariamente no GitHub. Na máquina, nenhuma nova geração é preparada
ou ativada automaticamente; a aplicação das atualizações é manual.

## Epson EcoTank L3210

- Impressão: CUPS com `epson-escpr2`.
- Digitalização USB: SANE com o backend `epsonscan2`.

Após conectar a multifuncional, adicione a impressora pelas Configurações do
Sistema do Plasma. Para verificar os modelos disponíveis:

```bash
lpinfo -m | grep -i epson
scanimage -L
```

## Vinyl

O flake fixa `github:ekaaty/vinyl-theme` como fonte externa e compila o conjunto
para Plasma 6. Ele é apenas instalado; a escolha do estilo, decoração, cores e
demais componentes continua sendo feita pela interface do Plasma.

## Comandos úteis

Validar sem ativar:

```bash
sudo nixos-rebuild build --flake .#nixos
```

Preparar para o próximo boot:

```bash
sudo nixos-rebuild boot --flake .#nixos
```

Ativar imediatamente uma alteração manual:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## Observações

- `system.stateVersion` permanece em `26.11`, mesmo quando o
  `nixos-unstable` avançar.
- Flatpak está habilitado, mas nenhum aplicativo ou repositório é instalado
  automaticamente.
- A configuração não instala Steam, Wine, ferramentas OpenCL, ModemManager,
  serviços de compartilhamento SMB, RDP ou suporte Wacom.
- Nenhum driver ou ajuste específico da controladora Realtek é declarado. A
  interface Intel usa o driver padrão do kernel através do NetworkManager.
