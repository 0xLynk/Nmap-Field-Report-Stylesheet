# Nmap Field Report Stylesheet

**Nmap Field Report Stylesheet** is a practical XSL transformation that converts Nmap XML output into a clean, interactive HTML report designed for real-world penetration testing and network assessment workflows.

This stylesheet focuses on **clarity, structure, and operator usability**. It presents Nmap results in a way that allows testers to reason about exposure quickly and accurately during active engagements and provide stakeholders with meaningful reports.

## Capabilities

- **Executive-level summary metrics**  
  Automatically summarizes hosts scanned, hosts online, open ports identified, and unique exposed services.

- **Interactive host discovery overview**  
  Searchable and sortable host table with status indicators, IP addresses, hostnames, OS detection, and open port counts.

- **Service exposure analysis**  
  Consolidated view of open ports and services per host, including protocol, encryption state, product name, and version details.

- **NSE script output organization**  
  Port-level and host-level NSE results are displayed in collapsible sections to maintain readability without losing detail.

- **Encrypted vs plaintext service visibility**  
  SSL/TLS services are visually flagged to quickly distinguish encrypted and unencrypted exposure.

- **Interactive tables with export support**  
  Built-in sorting, filtering, pagination, and export options (Copy, CSV, Excel, PDF).

- **Print-friendly layout**  
  Optimized styling for exporting or printing reports while preserving structure.

---

## Usage

### Convert an Existing Nmap XML File

If you already have an Nmap scan saved in XML format, convert it into an interactive HTML report using:

```bash
xsltproc -o report.html nmap-field-report.xsl scan.xml
```

