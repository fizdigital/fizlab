const labels = { ssh: "SSH", cron: "Cron", nginx: "Nginx", api: "API" };

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

const setStatus = (element, status) => {
    element.className = `status status-${status}`;
    element.textContent = ({ healthy: "Saudável", degraded: "Atenção", down: "Inativo" })[status] || status;
};

const render = (data) => {
    const system = data.system;
    document.querySelector("#node-name").textContent = `${system.hostname} · ${system.local_ip}`;
    setStatus(document.querySelector("#overall-status"), data.status);

    document.querySelector("#cpu-value").textContent = `${system.load_percent}%`;
    document.querySelector("#cpu-detail").textContent = `${system.cpu_count} núcleos · load ${system.load_average[0] ?? "—"}`;
    document.querySelector("#memory-value").textContent = `${system.memory.percent}%`;
    document.querySelector("#memory-detail").textContent = `${formatBytes(system.memory.used_bytes)} de ${formatBytes(system.memory.total_bytes)}`;
    document.querySelector("#storage-value").textContent = `${system.storage.percent}%`;
    document.querySelector("#storage-detail").textContent = `${formatBytes(system.storage.free_bytes)} livres`;
    document.querySelector("#uptime-value").textContent = formatDuration(system.uptime_seconds);

    document.querySelector("#services").innerHTML = Object.entries(data.services).map(([name, service]) => `
        <div class="service">
            <span class="service-name">${labels[name] || name}</span>
            <span class="service-state ${service.status}">${service.status}</span>
        </div>
    `).join("");

    const details = [
        ["Plataforma", system.platform],
        ["Arquitetura", system.architecture],
        ["Diretório", system.server_home],
        ["Versão FizLab", data.version],
    ];
    document.querySelector("#system-details").innerHTML = details.map(([key, value]) => `<div><dt>${key}</dt><dd>${value}</dd></div>`).join("");

    const commandWarnings = data.doctor.warnings.length;
    const failures = data.doctor.failures.length;
    document.querySelector("#doctor-summary").innerHTML = `
        <strong>${data.doctor.status === "healthy" ? "Estrutura aprovada" : "Diagnóstico requer atenção"}</strong><br>
        ${failures} falha(s) estrutural(is) · ${commandWarnings} comando(s) ausente(s)
    `;
    document.querySelector("#last-update").textContent = `Atualizado ${new Date(data.timestamp).toLocaleTimeString("pt-BR")}`;
};

const refresh = async () => {
    const error = document.querySelector("#connection-error");
    try {
        const response = await fetch("/api/v1/status", { cache: "no-store" });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        render(await response.json());
        error.hidden = true;
    } catch (reason) {
        setStatus(document.querySelector("#overall-status"), "down");
        error.textContent = `Não foi possível consultar a API: ${reason.message}`;
        error.hidden = false;
    }
};

refresh();
setInterval(refresh, 10000);
