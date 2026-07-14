# mri_Qfps — Manual

Menu de otimização gráfica (presets de FPS, ajuste fino de LOD/luzes/sombras, filtros de timecycle) e mira customizada em NUI, com todas as preferências salvas localmente no cliente.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Comandos](#comandos)
5. [Presets de FPS](#presets-de-fps)
6. [Ajuste fino](#ajuste-fino)
7. [Filtros gráficos (timecycle)](#filtros-gráficos-timecycle)
8. [Mira customizada](#mira-customizada)
9. [Persistência (KVP)](#persistência-kvp)
10. [Integrações](#integrações)
11. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
12. [Localização](#localização)
13. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Declarado em `dependencies`. Fornece `lib.addCommand`, locale e `cache.ped` |
| `qbx_core` | Sim | O client carrega `@qbx_core/modules/playerdata.lua` e reinicializa no evento `QBCore:Client:OnPlayerLoaded` |
| `oxmysql` | Sim | Carregado pelo `fxmanifest` (`@oxmysql/lib/MySQL.lua`), embora o recurso não faça queries |
| `mri_Qbox` | Não | Injeta a entrada "MRI FPS Menu" no menu de jogador (F9) |

---

## Instalação

1. Compile a UI (o `ui_page` aponta para `ui/dist/index.html`, que não vem versionado):
   ```
   cd ui
   pnpm install
   pnpm build
   ```
2. Copie a pasta `mri_Qfps` para `resources/`.
3. Adicione ao `server.cfg`:
   ```
   ensure mri_Qfps
   ```
4. Não há SQL a importar — o recurso não persiste nada no banco.

---

## Configuração

O único arquivo de configuração é `shared/config.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.LoadingDistanceEnabled` | bool | Sim | Quando `true`, o valor de distância de renderização (LOD) salvo em KVP é carregado na inicialização e aplicado a cada frame via `OverrideLodscaleThisFrame`. Quando `false`, o LOD nunca é sobrescrito e o loop do FPS boost roda a cada 500 ms em vez de a cada frame |
| `Config.IconAnimation` | bool | Não | Presente no config, mas não é lido por nenhum arquivo Lua do recurso na versão atual |

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/fps` | Todos | Abre o menu de FPS/GFX/Mira. Registrado via `lib.addCommand`, sem restrição de grupo |

---

## Presets de FPS

Selecionados na aba "FPS" do menu. Cada preset ajusta sombras (cascade shadows), corte de luzes e, no caso do `ulow`, dispara também a rotina de limpeza `Optimize`.

| Preset | Rótulo na UI | Efeito |
|---|---|---|
| `default` | Padrão (PC Gamer) | Restaura sombras e luzes conforme os valores dos sliders; sem otimizações agressivas |
| `medium` | Médio (PC Mediano) | Sombras em escala 3.0–5.0, corte de luzes em 3.0 |
| `low` | Baixo (PC Fraco) | Sombras desligadas, corte de luzes em 5.0 |
| `ulow` | Ultra Low (Batata-Gamer) | Sombras e luzes zeradas, radar oculto, e executa a limpeza `Optimize`: remove chuva, vento, sujeira/molhado do ped, sangue, vidros quebrados, mensagens de ajuda, blur de tela e sirenes distantes |

O preset `ulow` é o único reaplicado automaticamente no boot do recurso (além do timecycle salvo).

---

## Ajuste fino

Três sliders na aba "FPS", aplicados ao clicar em "APLICAR AJUSTES". São salvos em KVP e reaplicados no próximo login.

| Slider | Faixa | Efeito no jogo |
|---|---|---|
| Distância de Renderização | 0.1 – 10.0 | `OverrideLodscaleThisFrame` — só tem efeito se `Config.LoadingDistanceEnabled = true` |
| Luzes Distantes | 0.0 – 10.0 | `SetLightsCutoffDistanceTweak` + `SetFlashLightFadeDistance`. Valores `<= 1.0` também desligam as luzes distantes de veículos |
| Sombras | 0.0 – 5.0 | Escala das cascade shadows. `0` desliga sombras de corda, tracker de entidades e AO blob do ped |

O botão "Resetar" volta os três sliders para `1.0` e o preset para `default`.

---

## Filtros gráficos (timecycle)

Aba "GFX". Aplica um `SetTimecycleModifier` (e opcionalmente um `SetExtraTimecycleModifier`) no cliente. A escolha é salva em KVP e reaplicada no boot.

| ID | Rótulo na UI | Extra |
|---|---|---|
| `default` | Padrão | — (limpa os modificadores) |
| `cinema` | Cinema | — |
| `yell_tunnel_nodirect` | Opção #2 | — |
| `tunnel` | Opção #3 | — |
| `MP_Powerplay_blend` | Opção #4 | `reflection_correct_ambient` |

---

## Mira customizada

Aba "Mira". Desenha uma mira em NUI (`CrosshairOverlay.tsx`) por cima do HUD e esconde a mira nativa (`HideHudComponentThisFrame(14)`) enquanto o jogador está em combate.

A mira só é exibida quando o jogador está armado **e** mirando, atirando ou com o botão de mira pressionado. Ao sair do combate, o overlay permanece por mais 500 ms para não piscar durante a animação de abaixar a arma. Fora de combate, o loop dorme (500 ms desarmado, 50 ms armado) para não custar frames.

### Parâmetros

| Campo | Tipo | Faixa | Descrição |
|---|---|---|---|
| `enabled` | bool | — | Liga/desliga a mira customizada |
| `size` | number | 0.5 – 10 | Comprimento das linhas |
| `thickness` | number | 0.5 – 5 | Espessura das linhas |
| `gap` | number | -10 – 10 | Abertura entre o centro e as linhas |
| `dot` | bool | — | Exibe um ponto central |
| `color_r` / `color_g` / `color_b` | number | 0 – 255 | Cor RGB |
| `alpha` | number | 0 – 255 | Opacidade |
| `outline` | bool | — | Contorno preto nas linhas |
| `outlineThickness` | number | 0.5 – 3 | Espessura do contorno |
| `style` | number | — | Estilo de renderização do overlay |

### Presets de mira

`Dot` (ponto central), `Cruz Fechada` (competitivo, verde com contorno), `Cruz Aberta` (clássico, branca) e `Nenhuma` (volta para a mira nativa do GTA).

---

## Persistência (KVP)

Todas as preferências são do jogador, não do servidor: ficam salvas no KVP local do cliente e sobrevivem a restarts do recurso e do jogo. Nada é enviado ao banco de dados.

| Chave | Conteúdo |
|---|---|
| `mri_Qfps:PresetFps` | Preset ativo |
| `mri_Qfps:TimecycleModifier` | Filtro gráfico ativo |
| `mri_Qfps:LodDistance` | Slider de distância de renderização |
| `mri_Qfps:LightsCutoff` / `mri_Qfps:LightsCutOff` | Slider de luzes |
| `mri_Qfps:ShadowsCutoff` / `mri_Qfps:ShadowsCutOff` | Slider de sombras |
| `mri_Qfps:Crosshair*` | 12 chaves com os parâmetros da mira (`Enabled`, `Size`, `Thickness`, `Gap`, `Dot`, `ColorR`, `ColorG`, `ColorB`, `Alpha`, `Outline`, `OutlineThickness`, `Style`) |

> Atenção: a gravação dos sliders usa as chaves `LightsCutOff`/`ShadowsCutOff`, enquanto a leitura no boot usa `LightsCutoff`/`ShadowsCutoff`. Na prática, os valores de luzes e sombras do ajuste fino não são restaurados após um restart — apenas o preset e o timecycle são.

---

## Integrações

### mri_Qbox

Se o `mri_Qbox` estiver iniciado, o recurso registra automaticamente uma entrada no menu de jogador via `exports["mri_Qbox"]:AddPlayerMenu`, com título e descrição vindos do locale (`menu.mriFpsTitle` / `menu.mriFpsDescription`), ícone `tools` e animação `fade`. Ao parar o recurso, a entrada é removida com `exports["mri_Qbox"]:RemovePlayerMenu`.

Sem o `mri_Qbox`, o menu continua acessível pelo comando `/fps`.

### Cor de destaque

O client lê `GlobalState.UIColors` na inicialização e expõe o valor como `ColorScheme`, compartilhando o esquema de cores da suite MRI.

---

## Entrypoints para outros recursos

### Evento `mri_Qfps:openFpsMenu`

Evento de rede que abre o menu. É o que o comando `/fps` dispara do servidor para o cliente, e pode ser usado por qualquer outro recurso.

```lua
-- do servidor, para um jogador específico
TriggerClientEvent('mri_Qfps:openFpsMenu', source)
```

O recurso não expõe exports.

---

## Localização

As strings do menu são traduzidas via `ox_lib` locale. Os arquivos ficam em `locales/`:

- `en.json` — inglês
- `pt-br.json` — português do Brasil

O locale ativo é definido pela convar `ox:locale` no `server.cfg`:

```
setr ox:locale "pt-br"
```

Os textos da NUI (rótulos de abas, sliders e presets) estão embutidos no React e não passam pelo sistema de locale.

---

## Estrutura de arquivos

```
mri_Qfps/
├── client/
│   └── main.lua              — presets, sliders, timecycle, loop da mira, KVP e callbacks NUI
├── server/
│   └── main.lua              — registra o comando /fps via lib.addCommand
├── shared/
│   └── config.lua            — Config.IconAnimation e Config.LoadingDistanceEnabled
├── ui/                       — fonte da NUI (React + Vite + Tailwind)
│   ├── src/
│   │   ├── App.tsx           — menu com as abas FPS, GFX e Mira
│   │   ├── CrosshairOverlay.tsx — desenho da mira customizada
│   │   ├── providers/VisibilityProvider.tsx — controle de visibilidade da NUI
│   │   └── utils/            — fetchNui, useNuiEvent, helpers
│   └── dist/                 — build gerado (ui_page); não versionado
├── locales/
│   ├── en.json
│   └── pt-br.json
└── fxmanifest.lua
```
