# Configuração NixOS — `nixos-config`

Configuração em flakes para as máquinas de Arthur, usando `nixos-unstable`, KDE
Plasma 6 e o display manager Ly. A configuração atual do desktop fica em
`hosts/desktop`; o esqueleto compartilhado do notebook fica em `hosts/notebook`.

## Estrutura

- `hosts/`: configurações e hardware específico de cada máquina.
- `modules/`: módulos reutilizáveis entre hosts.
- `overlays/`: pacotes locais e o tema Vinyl.
- `packages/`: derivação do Free Download Manager.

## Antes da instalação

1. Inicialize a mídia do NixOS em modo UEFI.
2. Monte as partições existentes sob `/mnt`, incluindo a ESP em `/mnt/boot`
   ou `/mnt/boot/efi`.
3. Clone este repositório em `/mnt/etc/nixos`.
4. Gere somente a configuração de hardware:

   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config \
     | sudo tee /mnt/etc/nixos/hosts/desktop/hardware-configuration.nix >/dev/null
   ```

5. Confirme que `hosts/desktop/hardware-configuration.nix` contém a raiz, a home separada
   (se houver) e a ESP montada sob `/boot`.

O arquivo do desktop está versionado porque contém os UUIDs da instalação
atual. O arquivo do notebook é apenas um placeholder e deve ser substituído
quando o equipamento chegar:

```bash
sudo nixos-generate-config --root /mnt --show-hardware-config \
  | sudo tee /mnt/etc/nixos/hosts/notebook/hardware-configuration.nix >/dev/null
```

Depois de substituir o placeholder, a saída `.#notebook` será disponibilizada
automaticamente pelo flake. Use sempre o nome explícito do host ao instalar ou
reconstruir, para não selecionar o desktop por engano:

```bash
sudo nixos-install --flake .#notebook
sudo nixos-rebuild switch --flake .#notebook
```

## Validar e instalar

Na raiz do repositório:

```bash
nix flake lock
nix flake check
sudo nixos-install --flake .#desktop
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
sudo nixos-rebuild build --flake .#desktop
```

Preparar para o próximo boot:

```bash
sudo nixos-rebuild boot --flake .#desktop
```

Ativar imediatamente uma alteração manual:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

## Observações

- `system.stateVersion` permanece em `26.11`, mesmo quando o
  `nixos-unstable` avançar.
- Flatpak está habilitado, mas nenhum aplicativo ou repositório é instalado
  automaticamente.
- A configuração do desktop não instala Steam, Wine, ferramentas OpenCL,
  ModemManager, serviços de compartilhamento SMB, RDP ou suporte Wacom. A Steam
  é habilitada somente no notebook, com as bibliotecas gráficas 32-bit.
- Nenhum driver ou ajuste específico da controladora Realtek é declarado. A
  interface Intel usa o driver padrão do kernel através do NetworkManager.
