-- Defeat Anime RNG: Auto Buy + Auto Roll + Anti-AFK
-- Compra 0.15s; pausa adicional entre rolagens 0s.
-- Configuracoes apenas nesta execucao. Sem confirmacao pelo inventario.
-- Auto Buy e Auto Roll comecam desligados. Anti-AFK tenta atuar ao ficar ocioso.

local player = game:GetService("Players").LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local COMPRA, VERIFICACAO, PAUSA_ROLAGEM = 0.15, 0.05, 0
local TIMEOUT_COMPRA, TIMEOUT_ROLAGEM = 4, 6

local nomes = [[Ace|Ainz|Aizen|Akaza|Aki|Alucard|Aqua|Arima|Asta (Demon)|Asta|Bambietta|Broly|Byakuya|Choi Jong-In|Choso|Cid|Dabi|Deidara|Denji|Diablo|Diego|Dio (Heaven)|Dio (Vampire)|Dio|Enel|Eren|Erza|Esil|Fern|Frieren|Gaara|Gabimaru|Gilgamesh|Gogeta|Gojo (Awakened)|Gojo|Goku (Super)|Goku|Gon|Gray|Gremmy|Griffith (Dark)|Griffith (Light)|Griffith|Grimmjow|Guts (Berserk)|Guts|Gyro|Himmel|Hisoka|Ichigo (Chains)|Ichigo (Hollow)|Ichigo (Mugen)|Ichigo|Isagi (Ego)|Isagi|Itachi|Itadori|Jiji|Jinwoo (Monarch)|Jinwoo|Jiren|Johnny (Act 1)|Johnny (Act 2)|Johnny (Act 3)|Johnny (Act 4)|Joker|Jotaro (The World)|Jotaro|Juuzou|Kaiser|Kakashi|Kaneki (Centipede)|Kaneki (Investigator)|Kaneki|Kashimo|Kazuma|Kisame|Kobeni|Konan|Kuzan|Levi|Luffy (Joy)|Luffy|Madara|Makima|Maturo|Megumi|Megumin|Meliodas|Mikasa|Mikey|Miku|Mob (100%)|Mob|Naruto (Fox)|Naruto (SageMode)|Natsu|Nelliel|Ness|Power|Reze (Hybrid)|Reze|Rimuru|Rin|Ryusei|Sae|Sakura|Sanji|Sasuke (Susan)|Sasuke (Ts)|Sasuke|Shinra|Star|Stark|Sukuna (Heian)|Superstar|Teto|Toph|Touka|Ulqiorra|Unohana|Uryu|Valentine|Vegeta|Yamamoto|Yuno|Zeke|Zetsu]]
local catalogo = string.split(nomes, "|")
table.sort(catalogo)
local validos = {}
for _, nome in ipairs(catalogo) do validos[nome] = true end
local mutacoes = {"Normal", "Gold", "Diamond", "Blossom", "Genius", "Astral", "Honored", "Angelic", "Seraph"}

for _, nome in ipairs({"PainelCompraTeste", "PainelAutoBuy", "PainelCompraRolagem"}) do
    local antigo = pg:FindFirstChild(nome)
    if antigo then antigo:Destroy() end
end

local ativo, autoBuy, autoRoll, pequeno = true, false, false, false
local atual, compraPendente, rolagemPendente, ultimaFoto
local regras = {}
local observados = setmetatable({}, {__mode = "k"})
local enviados = setmetatable({}, {__mode = "k"})
local ids = setmetatable({}, {__mode = "k"})
local proximoId, tentativas = 0, 0
local ultimaCompra, ultimaMudanca = -math.huge, os.clock()

local gui = Instance.new("ScreenGui")
gui.Name = "PainelCompraRolagem"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = pg

local branco = Color3.new(1, 1, 1)
local cinza = Color3.fromRGB(48, 53, 65)
local verde = Color3.fromRGB(32, 125, 82)
local function criar(classe, props, pai)
    local obj = Instance.new(classe)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = pai
    return obj
end
local painel = criar("Frame", {
    Position = UDim2.fromScale(0.03, 0.03), Size = UDim2.fromScale(0.94, 0.88),
    BackgroundColor3 = Color3.fromRGB(24, 27, 35)
}, gui)
local titulo = criar("TextLabel", {
    Size = UDim2.new(0.65, 0, 0, 30), BackgroundTransparency = 1,
    TextColor3 = branco, TextSize = 12, TextWrapped = true, Text = "Auto Buy + Auto Roll"
}, painel)
local function botao(texto, pos, tamanho, pai)
    return criar("TextButton", {Text = texto, Position = pos, Size = tamanho,
        BackgroundColor3 = cinza, TextColor3 = branco, TextSize = 12, TextWrapped = true}, pai)
end
local minimizar = botao("Minimizar", UDim2.new(0.66, 0, 0, 2), UDim2.new(0.22, 0, 0, 26), painel)
local fechar = botao("X", UDim2.new(0.90, 0, 0, 2), UDim2.new(0.08, 0, 0, 26), painel)
local corpo = criar("Frame", {Position = UDim2.fromOffset(0, 34),
    Size = UDim2.new(1, 0, 1, -34), BackgroundTransparency = 1}, painel)
local busca = criar("TextBox", {
    Position = UDim2.fromScale(0.02, 0), Size = UDim2.fromScale(0.46, 0.08),
    BackgroundColor3 = cinza, TextColor3 = branco, PlaceholderText = "Pesquisar personagem",
    Text = "", TextSize = 13, ClearTextOnFocus = false
}, corpo)
local escolhido = criar("TextLabel", {
    Position = UDim2.fromScale(0.51, 0), Size = UDim2.fromScale(0.47, 0.08),
    BackgroundTransparency = 1, TextColor3 = branco, TextSize = 13,
    TextWrapped = true, Text = "Escolha para configurar"
}, corpo)
local function criarLista(x)
    local obj = criar("ScrollingFrame", {
        Position = UDim2.fromScale(x, 0.10), Size = UDim2.fromScale(0.46, 0.48),
        BackgroundTransparency = 1, ScrollBarThickness = 6, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, corpo)
    criar("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, obj)
    return obj
end
local lista, listaMutacoes = criarLista(0.02), criarLista(0.51)
local status = criar("TextLabel", {
    Position = UDim2.fromScale(0.02, 0.59), Size = UDim2.fromScale(0.96, 0.09),
    BackgroundTransparency = 1, TextColor3 = branco, TextSize = 12,
    TextWrapped = true, Text = "Aguardando..."
}, corpo)
local mensagem = criar("TextLabel", {
    Position = UDim2.fromScale(0.02, 0.69), Size = UDim2.fromScale(0.96, 0.10),
    BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 220, 130),
    TextSize = 12, TextWrapped = true,
    Text = "Configure os personagens. Depois ligue os dois botoes."
}, corpo)
local buyButton = botao("Auto Buy: DESLIGADO", UDim2.fromScale(0.02, 0.81), UDim2.fromScale(0.96, 0.08), corpo)
local rollButton = botao("Auto Roll: DESLIGADO", UDim2.fromScale(0.02, 0.91), UDim2.fromScale(0.96, 0.08), corpo)
local botoes, botoesMutacoes = {}, {}
local function informar(texto)
    if ativo then mensagem.Text = texto end
end
local function atualizar()
    local configurados = 0
    for nome, b in pairs(botoes) do
        local n = 0
        for _, marcado in pairs(regras[nome] or {}) do
            if marcado then n = n + 1 end
        end
        if n > 0 then configurados = configurados + 1 end
        b.Text = (n > 0 and "[X] " or "") .. nome .. (n > 0 and (" [" .. n .. "]") or "")
        b.BackgroundColor3 = nome == atual and verde or cinza
    end
    for nome, b in pairs(botoesMutacoes) do
        local marcado = atual and regras[atual] and regras[atual][nome]
        b.Text = (marcado and "[X] " or "[ ] ") .. nome
        b.BackgroundColor3 = marcado and verde or cinza
    end
    buyButton.Text = "Auto Buy: " .. (autoBuy and "LIGADO" or "DESLIGADO")
    rollButton.Text = "Auto Roll: " .. (autoRoll and "LIGADO" or "DESLIGADO")
    buyButton.BackgroundColor3 = autoBuy and verde or cinza
    rollButton.BackgroundColor3 = autoRoll and verde or cinza
    titulo.Text = configurados .. " configurados | 0,15s" .. (autoRoll and " | ROLANDO" or "")
end
for i, nome in ipairs(catalogo) do
    local b = botao(nome, UDim2.new(), UDim2.new(1, -10, 0, 32), lista)
    b.LayoutOrder, botoes[nome] = i, b
    b.Activated:Connect(function()
        atual = nome
        regras[nome] = regras[nome] or {}
        escolhido.Text = nome
        atualizar()
    end)
end
for i, nome in ipairs(mutacoes) do
    local b = botao("[ ] " .. nome, UDim2.new(), UDim2.new(1, -10, 0, 29), listaMutacoes)
    b.LayoutOrder, botoesMutacoes[nome] = i, b
    b.Activated:Connect(function()
        if not atual then informar("Escolha primeiro um personagem."); return end
        regras[atual][nome] = not regras[atual][nome]
        atualizar()
    end)
end
busca:GetPropertyChangedSignal("Text"):Connect(function()
    local filtro = busca.Text:lower()
    for nome, b in pairs(botoes) do
        b.Visible = nome:lower():find(filtro, 1, true) ~= nil
    end
    lista.CanvasPosition = Vector2.zero
end)

local function maquina()
    local bases = workspace:FindFirstChild("Bases")
    if not bases then return nil end
    for _, base in ipairs(bases:GetChildren()) do
        local owner = base:FindFirstChild("Owner")
        if owner and owner:IsA("ValueBase") then
            local valor = owner.Value
            if valor == player or tostring(valor) == tostring(player.UserId)
                or tostring(valor) == player.Name then
                return base:FindFirstChild("RollStation")
            end
        end
    end
end
local function texto(modelo, campo)
    local head = modelo:FindFirstChild("Head")
    local holder = head and head:FindFirstChild(campo)
    local desc = holder and holder:FindFirstChild("Desc")
    if desc and (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
        return desc.Text:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
    end
    return ""
end
local function ler(modelo)
    if not modelo:IsA("Model") or not modelo:FindFirstChild("Head") then return nil end
    local nome = modelo:GetAttribute("UnitName")
    if type(nome) ~= "string" or nome == "" then
        if not validos[modelo.Name] then return nil end
        nome = modelo.Name
    end
    local mutacao = texto(modelo, "Mutation")
    local lower = mutacao:lower()
    if lower == "" or lower == "normal" or lower == "no mutation" then
        mutacao = "Normal"
    else
        for _, m in ipairs(mutacoes) do
            if m:lower() == lower then mutacao = m; break end
        end
    end
    local prompt
    for _, obj in ipairs(modelo:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local acao = obj.ActionText:lower():match("^%s*(.-)%s*$")
            if acao == "collect" or acao == "coletar" then prompt = obj; break end
        end
    end
    local preco = texto(modelo, "Price")
    return {modelo = modelo, nome = nome, mutacao = mutacao, preco = preco, prompt = prompt,
        assinatura = table.concat({nome, mutacao, preco, tostring(modelo:GetAttribute("UnitId") or "")}, "|")}
end
local function selecionado(d)
    return regras[d.nome] and regras[d.nome][d.mutacao] == true
end
local function perto(prompt)
    if not prompt or not prompt.Enabled then return false end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local pai, pos = prompt.Parent, nil
    if pai:IsA("Attachment") then pos = pai.WorldPosition
    elseif pai:IsA("BasePart") then pos = pai.Position
    elseif pai:IsA("Model") then pos = pai:GetPivot().Position end
    return pos and (root.Position - pos).Magnitude <= prompt.MaxActivationDistance
end
local function promptRolar(station)
    local button = station:FindFirstChild("Button")
    local model = button and button:FindFirstChild("Model")
    local roll = model and model:FindFirstChild("RollButton")
    local prompt = roll and roll:FindFirstChild("ProximityPrompt")
    if prompt and prompt:IsA("ProximityPrompt") then return prompt end
end
local function pararRolagem(motivo)
    autoRoll, rolagemPendente = false, nil
    informar(motivo)
    atualizar()
end
buyButton.Activated:Connect(function()
    if autoBuy then
        autoBuy, autoRoll = false, false
        informar("Auto Buy e Auto Roll desligados.")
        atualizar()
        return
    end
    if type(fireproximityprompt) ~= "function" then informar("Funcao de interacao indisponivel."); return end
    local temRegra = false
    for _, regra in pairs(regras) do
        for _, marcado in pairs(regra) do
            if marcado then temRegra = true end
        end
    end
    if not temRegra then informar("Marque uma mutacao de pelo menos um personagem."); return end
    autoBuy = true
    informar("Auto Buy ligado.")
    atualizar()
end)
rollButton.Activated:Connect(function()
    if autoRoll then
        autoRoll = false
        informar("Auto Roll desligado. Auto Buy permanece como estava.")
    elseif not autoBuy then informar("Ligue o Auto Buy primeiro."); return
    elseif compraPendente then informar("Aguarde a saida do boneco da compra pendente."); return
    else
        autoRoll = true
        ultimaMudanca = os.clock()
        informar("Auto Roll ligado. Fique proximo da maquina.")
    end
    atualizar()
end)
minimizar.Activated:Connect(function()
    pequeno = not pequeno
    corpo.Visible = not pequeno
    painel.Size = pequeno and UDim2.new(0.94, 0, 0, 34) or UDim2.fromScale(0.94, 0.88)
    minimizar.Text = pequeno and "Expandir" or "Minimizar"
end)

-- Anti-AFK: uma tentativa de simular atividade ao receber Idled.
-- A permissao do VirtualUser depende do executor. Nao impede suspensao do app.
local conexaoAntiAfk
local antiAfkOcupado = false
local antiAfkEstado = "aguardando inatividade"
local antiAfkOk, antiAfkErro = pcall(function()
    local virtualUser = game:GetService("VirtualUser")
    conexaoAntiAfk = player.Idled:Connect(function()
        if not ativo or antiAfkOcupado then return end
        antiAfkOcupado = true
        local sucesso, falha = pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new(0, 0))
        end)
        antiAfkOcupado = false
        if sucesso then
            antiAfkEstado = "atividade simulada"
        else
            antiAfkEstado = "falhou; veja console"
            warn("[Anti-AFK]", falha)
        end
    end)
end)
if not antiAfkOk then
    antiAfkEstado = "indisponivel"
    warn("[Anti-AFK]", antiAfkErro)
end
gui.Destroying:Connect(function()
    ativo, autoBuy, autoRoll = false, false, false
    if conexaoAntiAfk then conexaoAntiAfk:Disconnect() end
end)
fechar.Activated:Connect(function()
    ativo, autoBuy, autoRoll = false, false, false
    gui:Destroy()
end)
atualizar()

task.spawn(function()
    while ativo do
        local ok, erro = pcall(function()
            local station = maquina()
            if not station then status.Text = "Sua maquina nao foi localizada."; return end
            local agora = os.clock()
            local dadosLista, fotoPartes = {}, {}
            local combinacoes, incompletos = 0, false
            for _, modelo in ipairs(station:GetChildren()) do
                local d = ler(modelo)
                if d then
                    table.insert(dadosLista, d)
                    if not ids[modelo] then proximoId = proximoId + 1; ids[modelo] = proximoId end
                    table.insert(fotoPartes, ids[modelo] .. ":" .. d.assinatura)
                    local obs = observados[modelo]
                    if not obs or obs.assinatura ~= d.assinatura or obs.prompt ~= d.prompt then
                        obs = {assinatura = d.assinatura, prompt = d.prompt, desde = agora}
                        observados[modelo] = obs
                    end
                    if d.preco == "" or not d.prompt or agora - obs.desde < COMPRA then incompletos = true end
                    if selecionado(d) then combinacoes = combinacoes + 1 end
                elseif modelo:IsA("Model") and (validos[modelo.Name] or modelo:GetAttribute("UnitName")) then
                    incompletos = true
                end
            end
            table.sort(fotoPartes)
            local foto = table.concat(fotoPartes, ";")
            if foto ~= ultimaFoto then ultimaFoto, ultimaMudanca = foto, agora end
            status.Text = "Bonecos: " .. #dadosLista .. " | Combinacoes: " .. combinacoes
                .. " | Tentativas: " .. tentativas .. "\nAnti-AFK: " .. antiAfkEstado

            if compraPendente then
                local pendente = compraPendente
                if not pendente.modelo:IsDescendantOf(station) then
                    compraPendente, ultimaMudanca = nil, agora
                    informar("Boneco saiu da maquina. Continuando.")
                elseif agora - pendente.inicio >= TIMEOUT_COMPRA then
                    if not pendente.avisado then
                        pendente.avisado = true
                        pararRolagem("Compra sem saida confirmada. Auto Roll pausado. Confira saldo e compra no jogo.")
                    end
                    return
                else return end
            end
            if rolagemPendente then
                if foto ~= rolagemPendente.antes then
                    rolagemPendente, ultimaMudanca = nil, agora
                elseif agora - rolagemPendente.inicio >= TIMEOUT_ROLAGEM then
                    pararRolagem("Rolagem sem mudanca detectada. Auto Roll pausado.")
                    return
                else return end
            end
            if not autoBuy then return end
            local existeAlvo, candidato = false, nil
            for _, d in ipairs(dadosLista) do
                if selecionado(d) then
                    existeAlvo = true
                    local obs = observados[d.modelo]
                    local jaEnviado = enviados[d.modelo] and enviados[d.modelo][d.assinatura]
                    if not jaEnviado and d.prompt and d.preco ~= ""
                        and agora - obs.desde >= COMPRA and perto(d.prompt) then
                        candidato = d
                        break
                    end
                end
            end
            if candidato and agora - ultimaCompra >= COMPRA then
                local d = ler(candidato.modelo)
                if not ativo or not autoBuy or not d or not selecionado(d)
                    or d.assinatura ~= candidato.assinatura or d.prompt ~= candidato.prompt
                    or not perto(d.prompt) or not d.modelo:IsDescendantOf(station) then return end
                enviados[d.modelo] = enviados[d.modelo] or {}
                enviados[d.modelo][d.assinatura] = true
                ultimaCompra = agora
                compraPendente = {modelo = d.modelo, inicio = agora, avisado = false}
                informar("Comprando: " .. d.nome .. " / " .. d.mutacao .. " / " .. d.preco)
                fireproximityprompt(d.prompt, d.prompt.HoldDuration)
                tentativas = tentativas + 1
                return
            end
            if existeAlvo then
                if not candidato then informar("Alvo presente. Aguardando dados ou aproximacao para comprar.") end
                return
            end
            if not autoRoll or incompletos or agora - ultimaMudanca < PAUSA_ROLAGEM then return end
            local prompt = promptRolar(station)
            if not perto(prompt) then informar("Aproxime-se do botao de rolar da sua maquina."); return end
            if not ativo or not autoBuy or not autoRoll then return end
            rolagemPendente = {antes = foto, inicio = agora}
            informar("Solicitando rolagem...")
            fireproximityprompt(prompt, prompt.HoldDuration)
        end)
        if not ok and ativo then
            autoBuy, autoRoll = false, false
            informar("Automacao parada: " .. tostring(erro))
            atualizar()
        end
        task.wait(VERIFICACAO)
    end
end)
