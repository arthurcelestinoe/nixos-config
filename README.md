# Configuração NixOS — `nixos`

Configuração em flakes para o desktop de Arthur, usando `nixos-unstable`,
Home Manager e duas especializações gráficas isoladas — KDE Plasma 6 e
Hyprland com Dank Material Shell — além de GRUB no caminho UEFI fallback
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
`os-prober` procura outros sistemas e o menu preserva no máximo dez gerações.
Cada geração oferece:

- **Plasma**: entrada padrão, com Plasma Workspace e Vinyl.
- **Hyprland + DMS**: Hyprland, portal próprio e serviços do DMS.
- **Base**: sistema comum sem ambiente gráfico, útil para manutenção.

Os ambientes não são habilitados juntos na configuração pai. Cada
especialização produz sua própria closure, enquanto aplicativos KDE escolhidos
(Dolphin, Kate, Okular etc.) permanecem deliberadamente na base comum.

Além das closures, cada ambiente possui árvores XDG independentes:

| Ambiente | Configuração | Cache | Dados | Estado |
| --- | --- | --- | --- | --- |
| Plasma | `~/.config/plasma` | `~/.cache/plasma` | `~/.local/share/plasma` | `~/.local/state/plasma` |
| Hyprland | `~/.config/hyprland` | `~/.cache/hyprland` | `~/.local/share/hyprland` | `~/.local/state/hyprland` |

Isso impede que arquivos como `environment.d`, `kdeglobals`, configurações do
`qt6ct` ou dados mutáveis do DMS alterem o comportamento da outra sessão.

O Plymouth usa o tema Breeze e oculta os logs durante a inicialização. Para
diagnosticar um boot, edite temporariamente a entrada do GRUB e remova `quiet`
e `splash` da linha do kernel.

## Atualizações

A Action `.github/workflows/update-flake-lock.yml` atualiza o `flake.lock`
diariamente às 11h30 no horário de São Paulo. Em **Settings → Actions → General
→ Workflow permissions**, habilite **Read and write permissions** para que o
bot possa enviar o commit.

Às 12h, o NixOS consulta `github:arthurcelestinoe/nixos-config#nixos` e executa
uma reconstrução com operação `boot`. A geração nova só é ativada no próximo
reinício. Reinicializações automáticas estão desabilitadas.

Se o Vinyl ou outro componente falhar com um kernel muito recente, a atualização
falha sem substituir a geração inicializável atual.

## Hyprland e Dank Material Shell

O DMS usa o flake oficial estável e seu módulo do Home Manager. Ele só é
habilitado quando a especialização contém a tag `hyprland`, portanto seu
serviço de usuário, Quickshell, variáveis e integrações não existem na closure
do Plasma.

Na primeira inicialização da especialização Hyprland, abra um terminal e gere
a configuração inicial do compositor:

```bash
dms setup
```

Depois disso, aparência e comportamento podem ser ajustados pela interface do
DMS. Estão habilitados monitoramento do sistema, tema dinâmico, visualizador de
áudio, VPN e calendário.

O `qt6ct` é instalado somente na especialização Hyprland e
`QT_QPA_PLATFORMTHEME=qt6ct` também existe apenas nessa sessão. Para ajustar o
estilo dos aplicativos Qt:

```bash
qt6ct
```

O portal do Hyprland trata captura de tela e integração com o compositor. As
requisições `FileChooser` são encaminhadas especificamente ao portal do COSMIC,
fornecendo seu seletor de arquivos sem instalar o desktop COSMIC completo.

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

Definir posteriormente a identidade do Git:

```bash
git config --global user.name "Arthur"
git config --global user.email "seu-email-publico@example.com"
```

## Observações

- `system.stateVersion` e `home.stateVersion` permanecem em `26.11`, mesmo
  quando o `nixos-unstable` avançar.
- Flatpak está habilitado, mas nenhum aplicativo ou repositório é instalado
  automaticamente.
- A configuração não instala Steam, Wine, ferramentas OpenCL, ModemManager,
  serviços de compartilhamento SMB, RDP ou suporte Wacom.
- Nenhum driver ou ajuste específico da controladora Realtek é declarado. A
  interface Intel usa o driver padrão do kernel através do NetworkManager.
