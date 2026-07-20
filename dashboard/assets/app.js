const labels = { ssh: "SSH", cron: "Cron", nginx: "Nginx", api: "FizLab API" };
const descriptions = { ssh: "Acesso remoto", cron: "Agendamentos", nginx: "Servidor web", api: "Dados e integração" };

const byId = (id) => document.getElementById(id);
const formatBytes = (bytes) => {
    if (!bytes) return "0 B";
    const units = ["B", "KB", "MB", "GB", "TB"];
    const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
    return `${(bytes / (1024 ** index)).toFixed(index > 2 ? 1 : 0)} ${units[index]}`;
};
const formatDuration = (seconds) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return [days && `${days}d`, hours && `${hours}h`, `${minutes}min`].filter(Boolean).join(" ");
};
const formatDate = (value) => value ? new Date(value).toLocaleString("pt-BR") : "Ainda não executado";
const setProgress = (id, value) => { byId(id).style.width = `${Math.max(0, Math.min(value, 100))}%`; };
const setHealth = (status) => {
    const element = byId("overall-status");
    element.className = `health-badge ${status}`;
    element.innerHTML = `<span></span>${({ healthy: "Sistema saudável", degraded: "Requer atenção", down: "Indisponível" })[status] || status}`;
};

const createServiceCard = (name, service) => {
    const card = document.createElement("article");
    card.className = "service-card";
    const top = document.createElement("div");
    top.className = "service-top";
    const title = document.createElement("span");
    title.className = "service-name";
    title.textContent = labels[name] || name;
    const state = document.createElement("span");
    state.className = `service-state ${service.status}`;
    state.textContent = service.running ? "Ativo" : (service.installed ? "Inativo" : "Indisponível");
    top.append(title, state);
    const meta = document.createElement("div");
    meta.className = "service-meta";
    const description = document.createElement("span");
    description.textContent = descriptions[name] || "Serviço do sistema";
    const availability = document.createElement("strong");
    availability.textContent = service.installed ? "Instalado" : "Ausente";
    meta.append(description, availability);
    card.append(top, meta);
    return card;
};

const render = (data) => {
    const system = data.system;
    byId("node-name").textContent = `${system.hostname} · ${system.local_ip} · ${system.platform}/${system.architecture}`;
    byId("sidebar-hostname").textContent = system.hostname;
    byId("sidebar-ip").textContent = system.local_ip;
    byId("sidebar-version").textContent = data.version;
    setHealth(data.status);

    byId("cpu-value").textContent = `${system.load_percent}%`;
    byId("cpu-detail").textContent = `${system.cpu_count} núcleos · load ${system.load_average[0] ?? "indisponível"}`;
    setProgress("cpu-progress", system.load_percent);
    byId("memory-value").textContent = `${system.memory.percent}%`;
    byId("memory-detail").textContent = `${formatBytes(system.memory.used_bytes)} de ${formatBytes(system.memory.total_bytes)}`;
    setProgress("memory-progress", system.memory.percent);
    byId("storage-value").textContent = `${system.storage.percent}%`;
    byId("storage-detail").textContent = `${formatBytes(system.storage.free_bytes)} livres de ${formatBytes(system.storage.total_bytes)}`;
    setProgress("storage-progress", system.storage.percent);
    byId("uptime-value").textContent = formatDuration(system.uptime_seconds);
    byId("last-watchdog").textContent = formatDate(data.monitoring?.last_watchdog);
    byId("last-maintenance").textContent = formatDate(data.monitoring?.last_maintenance);
    byId("logs-total").textContent = `${formatBytes(data.monitoring?.logs_size_bytes || 0)} em logs ativos`;
    const remote = data.remote_access || {};
    const remoteWarnings = remote.audit?.warnings || [];
    byId("remote-dashboard").textContent = remote.dashboard_access === "tailnet" ? "Somente Tailnet" : "Rede local";
    byId("remote-ssh").textContent = remote.ssh_hardening === "enabled" ? "Chave + Tailnet" : "Aguardando política";
    byId("remote-state").textContent = remote.audit?.visibility === "limited" ? "Visibilidade limitada" : (remoteWarnings.length ? `${remoteWarnings.length} alerta(s)` : "Auditado");
    byId("remote-summary").textContent = remoteWarnings.length ? remoteWarnings.join(" ") : "Nenhuma porta de rede inesperada foi identificada pela auditoria do FizLab.";

    const services = byId("services-list");
    services.replaceChildren(...Object.entries(data.services).map(([name, service]) => createServiceCard(name, service)));

    const details = [
        ["Plataforma", system.platform], ["Arquitetura", system.architecture],
        ["Hostname", system.hostname], ["Endereço local", system.local_ip],
        ["Diretório FizLab", system.server_home], ["Versão", data.version],
    ];
    const detailList = byId("system-details");
    detailList.replaceChildren(...details.map(([key, value]) => {
        const row = document.createElement("div");
        const term = document.createElement("dt"); term.textContent = key;
        const description = document.createElement("dd"); description.textContent = value;
        row.append(term, description);
        return row;
    }));

    const failures = data.doctor.failures.length;
    const warnings = data.doctor.warnings.length;
    const doctor = byId("doctor-summary");
    doctor.querySelector("div").innerHTML = `<strong>${failures ? "Diagnóstico requer atenção" : "Estrutura aprovada"}</strong><br>${failures} falha(s) · ${warnings} comando(s) ausente(s)`;
    byId("doctor-status").textContent = data.doctor.status === "healthy" ? "Aprovado" : "Atenção";
    byId("last-update").textContent = `Atualizado às ${new Date(data.timestamp).toLocaleTimeString("pt-BR")}`;
};

const loadLog = async () => {
    const id = byId("log-select").value;
    if (!id) return;
    const output = byId("log-output");
    output.textContent = "Carregando…";
    try {
        const response = await fetch(`/api/v1/logs/${encodeURIComponent(id)}?lines=200`, { cache: "no-store" });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        output.textContent = data.lines.length ? data.lines.join("\n") : "O arquivo está vazio.";
        byId("log-meta").textContent = `${formatBytes(data.size_bytes)} · ${data.line_count} linhas exibidas${data.truncated ? " · conteúdo limitado" : ""}`;
        output.scrollTop = output.scrollHeight;
    } catch (error) {
        output.textContent = `Não foi possível carregar o log: ${error.message}`;
    }
};

const loadLogCatalog = async () => {
    const response = await fetch("/api/v1/logs", { cache: "no-store" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    const select = byId("log-select");
    select.replaceChildren(...data.logs.map((log) => {
        const option = document.createElement("option");
        option.value = log.id;
        option.textContent = `${log.name}${log.available ? "" : " (sem dados)"}`;
        option.disabled = !log.available;
        return option;
    }));
    const available = data.logs.find((log) => log.available);
    if (available) {
        select.value = available.id;
        await loadLog();
    } else {
        select.insertAdjacentHTML("afterbegin", '<option value="">Nenhum log disponível</option>');
        select.value = "";
    }
};

const refresh = async () => {
    const errorBox = byId("connection-error");
    try {
        const response = await fetch("/api/v1/status", { cache: "no-store" });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        render(await response.json());
        errorBox.hidden = true;
    } catch (error) {
        setHealth("down");
        errorBox.textContent = `Não foi possível consultar a API: ${error.message}`;
        errorBox.hidden = false;
    }
};

document.querySelectorAll(".nav-link").forEach((link) => link.addEventListener("click", () => {
    document.querySelectorAll(".nav-link").forEach((item) => item.classList.remove("active"));
    link.classList.add("active");
}));
byId("log-select").addEventListener("change", loadLog);
byId("refresh-log").addEventListener("click", loadLog);

refresh();
loadLogCatalog().catch((error) => { byId("log-output").textContent = `Falha ao listar logs: ${error.message}`; });
setInterval(refresh, 10000);
