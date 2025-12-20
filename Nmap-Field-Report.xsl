<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="utf-8" indent="yes" doctype-system="about:legacy-compat"/>
  
  <xsl:key name="hosts-by-state" match="nmaprun/host" use="status/@state"/>
  <xsl:key name="ports-by-service" match="nmaprun/host/ports/port[state/@state='open']" use="service/@name"/>
  
  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="referrer" content="no-referrer"/>
        <title>Network Scan Report - <xsl:value-of select="/nmaprun/@startstr"/></title>
        
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"/>
        <link href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css" rel="stylesheet"/>
        <link href="https://cdn.datatables.net/buttons/2.4.1/css/buttons.bootstrap5.min.css" rel="stylesheet"/>

        <style>
          :root {
            --primary-color: #2c3e50;
            --secondary-color: #34495e;
            --success-color: #27ae60;
            --warning-color: #f39c12;
            --danger-color: #e74c3c;
            --info-color: #3498db;
          }
          
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            padding-top: 70px;
          }
          
          .navbar {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          
          .navbar-brand {
            font-weight: 700;
            font-size: 1.5rem;
          }
          
          .summary-card {
            border: none;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.07);
            transition: transform 0.2s, box-shadow 0.2s;
            margin-bottom: 20px;
          }
          
          .summary-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 12px rgba(0,0,0,0.15);
          }
          
          .summary-card .card-body {
            padding: 1.5rem;
          }
          
          .summary-number {
            font-size: 2.5rem;
            font-weight: 700;
            margin: 0;
          }
          
          .summary-label {
            font-size: 0.9rem;
            color: #6c757d;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          
          .section-header {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white;
            padding: 1rem 1.5rem;
            border-radius: 8px;
            margin: 2rem 0 1rem 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          
          .section-header h2 {
            margin: 0;
            font-size: 1.5rem;
            font-weight: 600;
          }
          
          .host-card {
            border: none;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
          }
          
          .host-card .card-header {
            background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%);
            color: white;
            border-radius: 8px 8px 0 0;
            padding: 1rem 1.5rem;
            font-weight: 600;
            cursor: pointer;
          }
          
          .port-table td, .port-table th {
            padding: 0.75rem;
            vertical-align: middle;
          }
          
          .state-open { background-color: #d4edda; }
          .state-filtered { background-color: #fff3cd; }
          .state-closed { background-color: #f8d7da; }
          
          .badge-service {
            font-size: 0.85rem;
            padding: 0.35rem 0.65rem;
          }
          
          pre {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            padding: 1rem;
            font-size: 0.9rem;
            white-space: pre-wrap;
            word-wrap: break-word;
          }
          
          .scan-metadata {
            background-color: white;
            border-radius: 8px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
          }
          
          .scan-metadata dt {
            font-weight: 600;
            color: var(--primary-color);
          }
          
          .scan-metadata dd {
            margin-bottom: 0.5rem;
          }
          
          .dataTable tbody tr:hover {
            background-color: #f1f3f5;
          }
          
          footer {
            margin-top: 4rem;
            padding: 2rem 0;
            background-color: var(--primary-color);
            color: white;
            text-align: center;
          }
          
          .accordion-button:not(.collapsed) {
            background-color: var(--secondary-color);
            color: white;
          }
          
          @media print {
            .no-print { display: none !important; }
            body { padding-top: 0; }
            .summary-card { break-inside: avoid; }
            .host-card { break-inside: avoid; }
            .navbar { display: none !important; }
            .collapse { display: block !important; }
            .accordion-button { display: none; }
            footer { page-break-before: always; }
            h2, h5 { page-break-after: avoid; }
            table { page-break-inside: avoid; }
          }

          #pdf-loading {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0,0,0,0.8);
            color: white;
            padding: 2rem 3rem;
            border-radius: 10px;
            z-index: 9999;
            display: none;
          }
        </style>
      </head>
      
      <body>
        <nav class="navbar navbar-expand-lg navbar-dark fixed-top no-print">
          <div class="container-fluid">
            <a class="navbar-brand" href="#">Network Scan Report</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
              <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
              <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="#executive-summary">Executive Summary</a></li>
                <li class="nav-item"><a class="nav-link" href="#host-discovery">Host Discovery</a></li>
                <li class="nav-item"><a class="nav-link" href="#service-analysis">Service Analysis</a></li>
                <li class="nav-item"><a class="nav-link" href="#detailed-hosts">Detailed Results</a></li>
                <li class="nav-item">
                  <button id="export-pdf" class="btn btn-outline-light btn-sm ms-2">
                    Export PDF
                  </button>
                </li>
              </ul>
            </div>
          </div>
        </nav>

        <div id="pdf-loading">
          <h4>Generating PDF...</h4>
          <p class="mb-0">This may take a few moments</p>
        </div>

        <div id="report-content" class="container-fluid" style="max-width: 1400px;">
          
          <section id="executive-summary">
            <div class="scan-metadata">
              <h1 class="mb-4">Network Security Assessment Report</h1>
              <dl class="row mb-0">
                <dt class="col-sm-3">Scan Start Time:</dt>
                <dd class="col-sm-9"><xsl:value-of select="/nmaprun/@startstr"/></dd>
                
                <dt class="col-sm-3">Scan End Time:</dt>
                <dd class="col-sm-9"><xsl:value-of select="/nmaprun/runstats/finished/@timestr"/></dd>
                
                <dt class="col-sm-3">Scanner Version:</dt>
                <dd class="col-sm-9">Nmap <xsl:value-of select="/nmaprun/@version"/></dd>
                
                <dt class="col-sm-3">Command Line:</dt>
                <dd class="col-sm-9"><code><xsl:value-of select="/nmaprun/@args"/></code></dd>
                
                <dt class="col-sm-3">Total Scan Time:</dt>
                <dd class="col-sm-9"><xsl:value-of select="/nmaprun/runstats/finished/@elapsed"/> seconds</dd>
              </dl>
            </div>

            <div class="row">
              <div class="col-md-3">
                <div class="summary-card card text-center">
                  <div class="card-body">
                    <div class="summary-label">Total Hosts Scanned</div>
                    <p class="summary-number text-primary">
                      <xsl:value-of select="count(/nmaprun/host)"/>
                    </p>
                  </div>
                </div>
              </div>
              
              <div class="col-md-3">
                <div class="summary-card card text-center">
                  <div class="card-body">
                    <div class="summary-label">Hosts Online</div>
                    <p class="summary-number text-success">
                      <xsl:value-of select="count(/nmaprun/host[status/@state='up'])"/>
                    </p>
                  </div>
                </div>
              </div>
              
              <div class="col-md-3">
                <div class="summary-card card text-center">
                  <div class="card-body">
                    <div class="summary-label">Open Ports Found</div>
                    <p class="summary-number text-info">
                      <xsl:value-of select="count(/nmaprun/host/ports/port[state/@state='open'])"/>
                    </p>
                  </div>
                </div>
              </div>
              
              <div class="col-md-3">
                <div class="summary-card card text-center">
                  <div class="card-body">
                    <div class="summary-label">Unique Services</div>
                    <p class="summary-number text-warning">
                      <xsl:value-of select="count(/nmaprun/host/ports/port[state/@state='open']/service[generate-id() = generate-id(key('ports-by-service', @name)[1])])"/>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section id="host-discovery">
            <div class="section-header">
              <h2>Host Discovery Overview</h2>
            </div>
            
            <div class="card">
              <div class="card-body">
                <div class="mb-3 no-print">
                  <label for="hostSearch" class="form-label fw-bold">Filter by IP Address:</label>
                  <input type="text" class="form-control host-search" id="hostSearch" placeholder="e.g., 10.10.110.3, 192.168..."/>
                  <small class="form-text text-muted">Search filters IP addresses only</small>
                </div>
                <div class="table-responsive">
                  <table id="host-table" class="table table-hover table-bordered">
                    <thead class="table-dark">
                      <tr>
                        <th>Status</th>
                        <th>IP Address</th>
                        <th>Hostname(s)</th>
                        <th>OS Detection</th>
                        <th>Open Ports</th>
                        <th class="no-print">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <xsl:for-each select="/nmaprun/host">
                        <xsl:sort select="status/@state" order="descending"/>
                        <xsl:sort select="address/@addr"/>
                        <tr>
                          <td>
                            <xsl:choose>
                              <xsl:when test="status/@state='up'">
                                <span class="badge bg-success">Up</span>
                              </xsl:when>
                              <xsl:otherwise>
                                <span class="badge bg-secondary">Down</span>
                              </xsl:otherwise>
                            </xsl:choose>
                          </td>
                          <td><strong><xsl:value-of select="address/@addr"/></strong></td>
                          <td>
                            <xsl:choose>
                              <xsl:when test="count(hostnames/hostname) > 0">
                                <xsl:for-each select="hostnames/hostname">
                                  <xsl:value-of select="@name"/>
                                  <xsl:if test="position() != last()">, </xsl:if>
                                </xsl:for-each>
                              </xsl:when>
                              <xsl:otherwise>
                                <em class="text-muted">No hostname</em>
                              </xsl:otherwise>
                            </xsl:choose>
                          </td>
                          <td>
                            <xsl:choose>
                              <xsl:when test="count(os/osmatch) > 0">
                                <xsl:value-of select="os/osmatch[1]/@name"/>
                                <br/><small class="text-muted">(<xsl:value-of select="os/osmatch[1]/@accuracy"/>% accuracy)</small>
                              </xsl:when>
                              <xsl:otherwise>
                                <em class="text-muted">Unknown</em>
                              </xsl:otherwise>
                            </xsl:choose>
                          </td>
                          <td class="text-center">
                            <span class="badge bg-info">
                              <xsl:value-of select="count(ports/port[state/@state='open'])"/>
                            </span>
                          </td>
                          <td class="no-print">
                            <a class="btn btn-sm btn-primary" data-bs-toggle="collapse">
                              <xsl:attribute name="href">#host-<xsl:value-of select="translate(address/@addr, '.:', '--')"/></xsl:attribute>
                              View Details
                            </a>
                          </td>
                        </tr>
                      </xsl:for-each>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </section>

          <section id="service-analysis">
            <div class="section-header">
              <h2>Service Analysis</h2>
            </div>
            
            <div class="card">
              <div class="card-body">
                <div class="mb-3 no-print">
                  <label for="serviceSearch" class="form-label fw-bold">Filter by Port Number:</label>
                  <input type="text" class="form-control service-search" id="serviceSearch" placeholder="e.g., 22, 80, 443, 3389..."/>
                  <small class="form-text text-muted">Search filters port numbers only</small>
                </div>

                <div class="table-responsive">
                  <table id="service-table" class="table table-hover table-bordered">
                    <thead class="table-dark">
                      <tr>
                        <th>IP Address</th>
                        <th>Hostname</th>
                        <th>Open Ports</th>
                        <th>Services Summary</th>
                      </tr>
                    </thead>
                    <tbody>
                      <xsl:for-each select="/nmaprun/host[status/@state='up' and count(ports/port[state/@state='open']) &gt; 0]">
                        <xsl:sort select="address/@addr"/>
                        <tr>
                          <td><strong><xsl:value-of select="address/@addr"/></strong></td>
                          <td>
                            <xsl:choose>
                              <xsl:when test="count(hostnames/hostname) &gt; 0">
                                <xsl:value-of select="hostnames/hostname[1]/@name"/>
                              </xsl:when>
                              <xsl:otherwise>
                                <em class="text-muted">-</em>
                              </xsl:otherwise>
                            </xsl:choose>
                          </td>
                          <td>
                            <xsl:for-each select="ports/port[state/@state='open']">
                              <xsl:sort select="@portid" data-type="number"/>
                              <span class="badge bg-primary me-1 mb-1">
                                <xsl:value-of select="@portid"/>/<xsl:value-of select="@protocol"/>
                              </span>
                              <xsl:text> </xsl:text>
                              <xsl:if test="position() mod 8 = 0"><br/></xsl:if>
                            </xsl:for-each>
                          </td>
                          <td>
                            <xsl:for-each select="ports/port[state/@state='open']">
                              <xsl:sort select="@portid" data-type="number"/>
                              <div class="mb-1">
                                <strong><xsl:value-of select="@portid"/>:</strong>
                                <xsl:text> </xsl:text>
                                <xsl:if test="service/@tunnel">
                                  <span class="badge bg-warning text-dark" style="font-size: 0.7rem;">SSL</span>
                                  <xsl:text> </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="service/@name"/>
                                <xsl:if test="service/@product">
                                  <xsl:text> - </xsl:text>
                                  <xsl:value-of select="service/@product"/>
                                  <xsl:if test="service/@version">
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="service/@version"/>
                                  </xsl:if>
                                </xsl:if>
                              </div>
                            </xsl:for-each>
                          </td>
                        </tr>
                      </xsl:for-each>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </section>

          <section id="detailed-hosts">
            <div class="section-header">
              <h2>Detailed Host Information</h2>
            </div>
            
            <xsl:for-each select="/nmaprun/host[status/@state='up']">
              <xsl:sort select="address/@addr"/>
              <div class="host-card card">
                <div class="card-header" data-bs-toggle="collapse">
                  <xsl:attribute name="data-bs-target">#host-<xsl:value-of select="translate(address/@addr, '.:', '--')"/></xsl:attribute>
                  <div class="row align-items-center">
                    <div class="col">
                      <strong><xsl:value-of select="address/@addr"/></strong>
                      <xsl:if test="count(hostnames/hostname) > 0">
                        - <xsl:value-of select="hostnames/hostname[1]/@name"/>
                      </xsl:if>
                    </div>
                    <div class="col-auto">
                      <span class="badge bg-light text-dark">
                        <xsl:value-of select="count(ports/port[state/@state='open'])"/> open ports
                      </span>
                    </div>
                  </div>
                </div>
                
                <div class="collapse show">
                  <xsl:attribute name="id">host-<xsl:value-of select="translate(address/@addr, '.:', '--')"/></xsl:attribute>
                  <div class="card-body">
                    
                    <div class="row mb-3">
                      <div class="col-md-6">
                        <h5>Host Information</h5>
                        <dl class="row">
                          <dt class="col-sm-4">IP Address:</dt>
                          <dd class="col-sm-8"><xsl:value-of select="address/@addr"/></dd>
                          
                          <dt class="col-sm-4">MAC Address:</dt>
                          <dd class="col-sm-8">
                            <xsl:choose>
                              <xsl:when test="address[@addrtype='mac']">
                                <xsl:value-of select="address[@addrtype='mac']/@addr"/>
                                <xsl:if test="address[@addrtype='mac']/@vendor">
                                  <br/><small class="text-muted">(<xsl:value-of select="address[@addrtype='mac']/@vendor"/>)</small>
                                </xsl:if>
                              </xsl:when>
                              <xsl:otherwise><em class="text-muted">N/A</em></xsl:otherwise>
                            </xsl:choose>
                          </dd>
                          
                          <dt class="col-sm-4">Hostnames:</dt>
                          <dd class="col-sm-8">
                            <xsl:choose>
                              <xsl:when test="count(hostnames/hostname) > 0">
                                <xsl:for-each select="hostnames/hostname">
                                  <xsl:value-of select="@name"/> (<xsl:value-of select="@type"/>)
                                  <xsl:if test="position() != last()"><br/></xsl:if>
                                </xsl:for-each>
                              </xsl:when>
                              <xsl:otherwise><em class="text-muted">None detected</em></xsl:otherwise>
                            </xsl:choose>
                          </dd>
                        </dl>
                      </div>
                      
                      <div class="col-md-6">
                        <h5>OS Detection</h5>
                        <xsl:choose>
                          <xsl:when test="count(os/osmatch) > 0">
                            <xsl:for-each select="os/osmatch[position() &lt;= 3]">
                              <div class="mb-2">
                                <strong><xsl:value-of select="@name"/></strong>
                                <div class="progress" style="height: 20px;">
                                  <div class="progress-bar bg-info" role="progressbar">
                                    <xsl:attribute name="style">width: <xsl:value-of select="@accuracy"/>%</xsl:attribute>
                                    <xsl:attribute name="aria-valuenow"><xsl:value-of select="@accuracy"/></xsl:attribute>
                                    <xsl:value-of select="@accuracy"/>%
                                  </div>
                                </div>
                              </div>
                            </xsl:for-each>
                          </xsl:when>
                          <xsl:otherwise>
                            <p class="text-muted"><em>OS detection not available</em></p>
                          </xsl:otherwise>
                        </xsl:choose>
                      </div>
                    </div>

                    <h5 class="mt-4">Open Ports and Services</h5>
                    <div class="table-responsive">
                      <table class="table table-sm table-bordered port-table">
                        <thead class="table-secondary">
                          <tr>
                            <th>Port</th>
                            <th>Protocol</th>
                            <th>State</th>
                            <th>Service</th>
                            <th>Product</th>
                            <th>Version</th>
                            <th>Details</th>
                          </tr>
                        </thead>
                        <tbody>
                          <xsl:for-each select="ports/port[state/@state='open']">
                            <xsl:sort select="@portid" data-type="number"/>
                            <tr class="state-{state/@state}">
                              <td><strong><xsl:value-of select="@portid"/></strong></td>
                              <td><xsl:value-of select="@protocol"/></td>
                              <td><span class="badge bg-success"><xsl:value-of select="state/@state"/></span></td>
                              <td>
                                <xsl:if test="service/@tunnel">
                                  <span class="badge bg-warning text-dark">SSL/TLS</span>
                                </xsl:if>
                                <xsl:value-of select="service/@name"/>
                              </td>
                              <td><xsl:value-of select="service/@product"/></td>
                              <td><xsl:value-of select="service/@version"/></td>
                              <td><small><xsl:value-of select="service/@extrainfo"/></small></td>
                            </tr>
                            
                            <xsl:if test="count(script) &gt; 0">
                              <tr>
                                <td colspan="7">
                                  <div class="accordion">
                                    <xsl:attribute name="id">scripts-<xsl:value-of select="translate(../../address/@addr, '.:', '--')"/>-<xsl:value-of select="@portid"/></xsl:attribute>
                                    <xsl:for-each select="script">
                                      <div class="accordion-item">
                                        <h2 class="accordion-header">
                                          <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse">
                                            <xsl:attribute name="data-bs-target">#script-<xsl:value-of select="translate(../../address/@addr, '.:', '--')"/>-<xsl:value-of select="../@portid"/>-<xsl:value-of select="position()"/></xsl:attribute>
                                            <strong><xsl:value-of select="@id"/></strong>
                                          </button>
                                        </h2>
                                        <div class="accordion-collapse collapse">
                                          <xsl:attribute name="id">script-<xsl:value-of select="translate(../../address/@addr, '.:', '--')"/>-<xsl:value-of select="../@portid"/>-<xsl:value-of select="position()"/></xsl:attribute>
                                          <div class="accordion-body">
                                            <pre><xsl:value-of select="@output"/></pre>
                                          </div>
                                        </div>
                                      </div>
                                    </xsl:for-each>
                                  </div>
                                </td>
                              </tr>
                            </xsl:if>
                          </xsl:for-each>
                        </tbody>
                      </table>
                    </div>

                    <xsl:if test="count(hostscript/script) &gt; 0">
                      <h5 class="mt-4">Host-Level Scripts</h5>
                      <div class="accordion">
                        <xsl:for-each select="hostscript/script">
                          <div class="accordion-item">
                            <h2 class="accordion-header">
                              <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse">
                                <xsl:attribute name="data-bs-target">#hostscript-<xsl:value-of select="translate(../../address/@addr, '.:', '--')"/>-<xsl:value-of select="position()"/></xsl:attribute>
                                <strong><xsl:value-of select="@id"/></strong>
                              </button>
                            </h2>
                            <div class="accordion-collapse collapse">
                              <xsl:attribute name="id">hostscript-<xsl:value-of select="translate(../../address/@addr, '.:', '--')"/>-<xsl:value-of select="position()"/></xsl:attribute>
                              <div class="accordion-body">
                                <pre><xsl:value-of select="@output"/></pre>
                              </div>
                            </div>
                          </div>
                        </xsl:for-each>
                      </div>
                    </xsl:if>

                  </div>
                </div>
              </div>
            </xsl:for-each>
          </section>

        </div>

        <footer>
          <div class="container">
            <p>Network Security Assessment Report Generated by Nmap</p>
            <p class="mb-0"><small>This report contains sensitive security information and should be treated as confidential.</small></p>
          </div>
        </footer>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>
        <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
        <script src="https://cdn.datatables.net/1.13.6/js/dataTables.bootstrap5.min.js"></script>
        <script src="https://cdn.datatables.net/buttons/2.4.1/js/dataTables.buttons.min.js"></script>
        <script src="https://cdn.datatables.net/buttons/2.4.1/js/buttons.bootstrap5.min.js"></script>
        <script src="https://cdn.datatables.net/buttons/2.4.1/js/buttons.html5.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>

        <script>
          <![CDATA[
          $(document).ready(function() {
            var hostTable = $('#host-table').DataTable({
              "pageLength": 25,
              "order": [[0, "desc"], [1, "asc"]]
            });

            $('.host-search').on('keyup', function() {
              var searchValue = this.value;
              hostTable.column(1).search(searchValue).draw();
            });

            var serviceTable = $('#service-table').DataTable({
              "pageLength": 50,
              "order": [[0, "asc"]],
              "dom": 'Bfrtip',
              "buttons": ['copy', 'csv', 'excel', 'pdf']
            });

            $('.service-search').on('keyup', function() {
              var searchValue = this.value;
              serviceTable.column(2).search(searchValue).draw();
            });

            $('#export-pdf').on('click', function() {
              var button = $(this);
              button.prop('disabled', true).text('Generating PDF...');
              
              try {
                const { jsPDF } = window.jspdf;
                const doc = new jsPDF('p', 'pt', 'letter');
                
                var scanStart = ']]><xsl:value-of select="/nmaprun/@startstr"/><![CDATA[';
                var scanEnd = ']]><xsl:value-of select="/nmaprun/runstats/finished/@timestr"/><![CDATA[';
                var nmapVersion = ']]><xsl:value-of select="/nmaprun/@version"/><![CDATA[';
                var totalHosts = ']]><xsl:value-of select="count(/nmaprun/host)"/><![CDATA[';
                var hostsUp = ']]><xsl:value-of select="count(/nmaprun/host[status/@state='up'])"/><![CDATA[';
                var openPorts = ']]><xsl:value-of select="count(/nmaprun/host/ports/port[state/@state='open'])"/><![CDATA[';
                
                var yPos = 40;
                
                doc.setFontSize(20);
                doc.setFont(undefined, 'bold');
                doc.text('Network Security Assessment Report', 40, yPos);
                
                yPos += 30;
                doc.setFontSize(10);
                doc.setFont(undefined, 'normal');
                doc.text('Scan Start: ' + scanStart, 40, yPos);
                yPos += 15;
                doc.text('Scan End: ' + scanEnd, 40, yPos);
                yPos += 15;
                doc.text('Nmap Version: ' + nmapVersion, 40, yPos);
                
                yPos += 30;
                doc.setFontSize(14);
                doc.setFont(undefined, 'bold');
                doc.text('Executive Summary', 40, yPos);
                yPos += 20;
                
                doc.setFontSize(10);
                doc.setFont(undefined, 'normal');
                doc.text('Total Hosts Scanned: ' + totalHosts, 40, yPos);
                yPos += 15;
                doc.text('Hosts Online: ' + hostsUp, 40, yPos);
                yPos += 15;
                doc.text('Open Ports Found: ' + openPorts, 40, yPos);
                
                yPos += 30;
                doc.setFontSize(14);
                doc.setFont(undefined, 'bold');
                doc.text('Host Discovery Overview', 40, yPos);
                yPos += 20;
                
                var hostTableData = [];
                $('#host-table tbody tr').each(function() {
                  var row = [];
                  $(this).find('td').slice(0, 5).each(function(index) {
                    if (index === 0) {
                      row.push($(this).text().trim());
                    } else {
                      row.push($(this).text().trim());
                    }
                  });
                  hostTableData.push(row);
                });
                
                doc.autoTable({
                  head: [['Status', 'IP Address', 'Hostname', 'OS', 'Ports']],
                  body: hostTableData,
                  startY: yPos,
                  styles: { fontSize: 8, cellPadding: 3 },
                  headStyles: { fillColor: [44, 62, 80], textColor: 255 },
                  alternateRowStyles: { fillColor: [245, 245, 245] },
                  margin: { left: 40, right: 40 }
                });
                
                yPos = doc.lastAutoTable.finalY + 30;
                
                if (yPos > 700) {
                  doc.addPage();
                  yPos = 40;
                }
                
                doc.setFontSize(14);
                doc.setFont(undefined, 'bold');
                doc.text('Service Analysis', 40, yPos);
                yPos += 20;
                
                var serviceTableData = [];
                $('#service-table tbody tr').each(function() {
                  var ip = $(this).find('td:eq(0)').text().trim();
                  var hostname = $(this).find('td:eq(1)').text().trim();
                  var ports = $(this).find('td:eq(2)').text().trim().replace(/\s+/g, ' ');
                  
                  serviceTableData.push([ip, hostname, ports]);
                });
                
                doc.autoTable({
                  head: [['IP Address', 'Hostname', 'Open Ports']],
                  body: serviceTableData,
                  startY: yPos,
                  styles: { fontSize: 8, cellPadding: 3 },
                  headStyles: { fillColor: [44, 62, 80], textColor: 255 },
                  alternateRowStyles: { fillColor: [245, 245, 245] },
                  margin: { left: 40, right: 40 },
                  columnStyles: {
                    2: { cellWidth: 200 }
                  }
                });
                
                var finalY = doc.lastAutoTable.finalY + 30;
                if (finalY < 750) {
                  doc.setFontSize(8);
                  doc.setFont(undefined, 'italic');
                  doc.text('This report contains sensitive security information and should be treated as confidential.', 40, 770);
                }
                
                doc.save('nmap-security-report.pdf');
                
                button.prop('disabled', false).text('Export PDF');
                
              } catch (error) {
                console.error('PDF Error:', error);
                alert('Error generating PDF: ' + error.message);
                button.prop('disabled', false).text('Export PDF');
              }
            });

            $('a[href^="#"]').on('click', function(event) {
              var target = $(this.getAttribute('href'));
              if(target.length) {
                event.preventDefault();
                $('html, body').stop().animate({
                  scrollTop: target.offset().top - 70
                }, 500);
              }
            });
          });
          ]]>
        </script>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet
