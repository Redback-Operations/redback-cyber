---
sidebar_position: 1
---
> **Document Creation:** 17 May 2025. **Last Edited:** 23 May 2025. **Authors:** Syed Mahmood Aleem Huzaifa.

> **Effective Date:** 23 May 2025. **Expiry Date:** 23 May 2026.

# Introduction to Configuration and Integration Files

This document provides an overview of the key files used in configuring and extending the capabilities of the Wazuh SIEM, Suricata IDS, and MISP threat intelligence integration. These files collectively support an automated threat hunting workflow by enabling rule-based detection, event enrichment, and correlation.

## Files Overview

### `ossec.conf`
This is the main configuration file for the Wazuh manager. It defines global parameters, rule integrations, logging behavior, remote communication settings, and agent management. It also includes references to local rules, Suricata EVE JSON log ingestion, and the integration with the custom MISP enrichment script.

### `custom_rules.xml`
This file contains custom detection rules tailored for specific threat scenarios not covered by the default Wazuh ruleset. For example, it includes a rule that detects SSH login failures, which can be useful for brute-force detection.

### `local_rules.xml`
This file defines custom rule groups and correlation logic for handling alerts within Wazuh. It includes logic for detecting authentication failures, SSH brute-force attempts, and events triggered by MISP-enriched data. These rules help raise the severity and visibility of incidents based on contextual threat intelligence.

### `custom-misp.py`
A custom Python script used to correlate Wazuh alerts with data from MISP (Malware Information Sharing Platform). It extracts IP addresses from alerts, queries the MISP API, and enriches the alerts with any matched IOCs (Indicators of Compromise). The enriched events are then re-injected into the Wazuh queue for correlation and further action.

### `suricata.yaml`
The primary configuration file for Suricata IDS. It defines capture methods, logging outputs (especially EVE JSON), alert handling, and protocol detection settings. This configuration enables Suricata to monitor network traffic and export structured logs that Wazuh can analyze.

## Purpose

Together, these files form the foundation of a modular, open-source-based threat detection and response system. They allow for:

- Real-time log and packet analysis
- Threat intelligence enrichment from MISP
- Custom rule writing and alert tuning
- Integration of host and network-level telemetry

This setup enables proactive detection, investigation, and response to cybersecurity threats using open standards and extensible tooling.
