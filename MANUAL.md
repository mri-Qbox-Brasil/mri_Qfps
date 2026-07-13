# MANUAL - mri_Qfps

## O que o recurso faz (descrição funcional)
Sistema de otimização de FPS para FiveM, oferecendo presets de performance (Padrão, Ultra Baixo, Baixo, Médio), sistema de crosshair personalizável com React NUI e detecção inteligente que reduz atualizações quando o jogador não está mirando.

## Funcionalidades principais
- **Presets de performance**: Ajuste de distância LOD, corte de luzes/sombras, modificador timecycle.
- **Sistema de crosshair**: Múltiplos estilos (ponto, cruz, círculo), personalizável via CSS puro (sem imagens).
- **Detecção inteligente**: Detecta quando o jogador está mirando, hiberna atualizações quando não está.
- **Configurações persistentes**: Armazenamento via KVP (Key-Value Pair), persiste entre reinícios.
- **Interface React**: UI moderna para seleção de presets e configuração de crosshair.

## Como funciona (fluxo de trabalho)

### Configuração de FPS (jogador)
1. Jogador usa comando `/fps` para abrir menu de configurações.
2. Seleciona preset desejado (Padrão, Ultra Baixo, Baixo, Médio).
3. Preset é aplicado imediatamente: ajusta LOD, luzes, sombras, timecycle.
4. Configuração é salva via KVP para persistência.

### Configuração de crosshair (jogador)
1. No mesmo menu `/fps`, acessa aba de crosshair.
2. Seleciona estilo: dot (ponto), cross (cruz), circle (círculo).
3. Ajusta tamanho, cor, opacidade, gap (para estilo cross).
4. Define se crosshair aparece apenas ao mirar ou sempre.

### Detecção inteligente
1. Sistema verifica periodicamente se o jogador está mirando (IsPlayerFreeAiming).
2. Se estiver mirando: atualiza crosshair normalmente.
3. Se não estiver: hiberna, aumenta intervalo de verificação (economia de CPU).

## Opções de configuração disponíveis
Configurações em config/config.lua:

| Opção | Padrão | Descrição |
|-------|--------|-----------|
| Config.Presets | (ver abaixo) | Definição dos presets de performance. |
| Config.DefaultPreset | 'default' | Preset padrão ao iniciar. |
| Config.Crosshair.enabled | true | Habilita sistema de crosshair. |
| Config.Crosshair.defaultVisible | false | Visibilidade padrão. |
| Config.Crosshair.styles | (dot/cross/circle) | Estilos disponíveis. |
| Config.SmartDetection.enabled | true | Habilita detecção inteligente. |
| Config.SmartDetection.hibernateWhenNotAiming | true | Hiberna quando não mira. |
| Config.SmartDetection.checkInterval | 100 | Intervalo de verificação em ms. |
| Config.UseKVP | true | Persiste configurações via KVP. |

### Presets disponíveis:
- **default**: lodDistance=100.0, lightsCutoff=50.0, shadowsCutoff=50.0, timecycle='DEFAULT'
- **ulow**: lodDistance=30.0, lightsCutoff=20.0, shadowsCutoff=0.0, timecycle='LOW'
- **low**: lodDistance=50.0, lightsCutoff=30.0, shadowsCutoff=20.0, timecycle='LOW'
- **medium**: lodDistance=75.0, lightsCutoff=40.0, shadowsCutoff=35.0, timecycle='MEDIUM'

## Comandos disponíveis
| Comando | Permissão | Descrição |
|---------|------------|-------------|
| `/fps` | Todos | Abre menu de configurações FPS. |

## Eventos que dispara/ouve

### Cliente → Servidor
| Evento | Parâmetros | Descrição |
|--------|------------|-----------|
| mri_Qfps:client:openMenu | none | Abre menu de configurações FPS. |
| mri_Qfps:client:setPreset | presetName | Aplica preset FPS. |
| mri_Qfps:client:toggleCrosshair | visible | Alterna visibilidade do crosshair. |
| mri_Qfps:client:setCrosshairStyle | style | Altera estilo do crosshair. |
| mri_Qfps:client:updateCrosshair | settings | Atualiza configurações do crosshair. |

### Servidor → Cliente
*Este recurso é primariamente do lado do cliente. Sem eventos significativos do servidor.*

## Exports que fornece/consome

### Exports do cliente
| Export | Parâmetros | Descrição |
|--------|------------|-----------|
| applyPreset | presetName | Aplica preset FPS (ex: 'low'). |
| getCurrentPreset | none | Obtém preset atual. |
| toggleCrosshair | visible | Alterna crosshair. |
| setCrosshairStyle | style | Define estilo do crosshair. |
| getPresets | none | Obtém presets disponíveis. |

### Exports do servidor
*Sem exports do servidor disponíveis (recurso do lado do cliente).*

### Exports consumidos
Nenhum export externo consumido, usa ox_lib para UI.

## Integração com outros recursos MRI Qbox
- **ox_lib**: Componentes UI e utilitários.
- Este é um recurso independente que atua no lado do cliente, não requer integração direta com outros recursos.

## Casos de uso / exemplos práticos
1. **Jogador com PC fraco**: Usa `/fps`, seleciona preset "Ultra Baixo", ganha FPS significativo.
2. **Atirador usa crosshair**: Jogador prefere mira em "cruz", configura via `/fps`, seleciona estilo cross, cor vermelha.
3. **Otimização automática**: Detecção inteligente percebe que jogador não está mirando, reduz atualizações, libera CPU.
4. **Persistência**: Jogador configura preset "Médio", reinicia jogo, configuração é mantida via KVP.

## Dicas de solução de problemas
- **Preset não aplica**: Verifique se o nome do preset está correto e se o recurso está iniciado.
- **Crosshair não aparece**: Confira se está com visibilidade ativada e se o estilo está configurado.
- **Interface não abre**: Confirme que ox_lib está instalado e iniciado.
- **Configuração não persiste**: Verifique se Config.UseKVP está true e se o FiveM suporta KVP.
- **Performance não melhora**: Teste diferentes presets, o sistema de detecção inteligente pode estar hibernando, aguarde alguns segundos.
