from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from lxml import etree


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
XML_NS = "http://www.w3.org/XML/1998/namespace"
W = f"{{{W_NS}}}"


SOURCE = Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project\Site2_SourceBased_Technical_Report_V3.0_NoPrompt.docx")
OUTPUTS = [
    Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project\Site2_SourceBased_Technical_Report_V3.1.docx"),
    Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project\Site2_SourceBased_Technical_Report_V3.1_NoPrompt.docx"),
]


def ensure_ppr(p):
    ppr = p.find(f"{W}pPr")
    if ppr is None:
        ppr = etree.Element(f"{W}pPr")
        p.insert(0, ppr)
    return ppr


def set_style(p, style):
    ppr = ensure_ppr(p)
    node = ppr.find(f"{W}pStyle")
    if style:
        if node is None:
            node = etree.Element(f"{W}pStyle")
            ppr.insert(0, node)
        node.set(f"{W}val", style)
    elif node is not None:
        ppr.remove(node)


def set_center(p, enabled):
    ppr = ensure_ppr(p)
    jc = ppr.find(f"{W}jc")
    if enabled:
        if jc is None:
            jc = etree.Element(f"{W}jc")
            ppr.append(jc)
        jc.set(f"{W}val", "center")
    elif jc is not None:
        ppr.remove(jc)


def set_text(p, text):
    ppr = p.find(f"{W}pPr")
    for child in list(p):
        if child is not ppr:
            p.remove(child)
    if text:
        r = etree.Element(f"{W}r")
        t = etree.SubElement(r, f"{W}t")
        if text[:1].isspace() or text[-1:].isspace():
            t.set(f"{{{XML_NS}}}space", "preserve")
        t.text = text
        p.append(r)


def make_paragraph(text, style):
    p = etree.Element(f"{W}p")
    if style:
        set_style(p, style)
    set_text(p, text)
    return p


def patch_document_xml(xml_bytes):
    root = etree.fromstring(xml_bytes)
    body = root.find(f"{W}body")
    paragraphs = body.findall(f"{W}p")

    cover_lines = [
        "Formal Technical Design, Validation, and Handover Report for the Site 2 Environment",
        "Supporting Company 1, Company 2, and MSP Operations",
        "",
        "Prepared by the Site 2 Infrastructure Delivery Team",
        "Version 3.1 | March 26, 2026",
        "",
        "Engineering Contributors: Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin Rosseleve, Yiqin Huang, Omer Deniz",
    ]

    for idx, p in enumerate(paragraphs[2:21]):
        text = cover_lines[idx] if idx < len(cover_lines) else ""
        set_style(p, None)
        set_center(p, True)
        set_text(p, text)

    list_of_figures_heading = paragraphs[50]
    for p in paragraphs[22:50]:
        body.remove(p)

    toc_entries = [
        ("TOC1", "Contents"),
        ("TOC1", "List of Figures"),
        ("TOC1", "List of Tables"),
        ("TOC1", "Executive Summary"),
        ("TOC1", "1. Introduction"),
        ("TOC1", "2. Background"),
        ("TOC2", "2.1 Design inputs and environment evidence"),
        ("TOC2", "2.2 Evidence classes used in this report"),
        ("TOC2", "2.3 Evidence-based method used for this report"),
        ("TOC2", "2.4 Observation method"),
        ("TOC2", "2.5 Delivery-phase change history and finalization decisions"),
        ("TOC1", "3. Discussion"),
        ("TOC2", "3.1 Environment overview and service boundaries"),
        ("TOC2", "3.2 Site 2 logical service inventory and platform roles"),
        ("TOC3", "Observed Linux VM platform baseline"),
        ("TOC3", "Service placement rationale"),
        ("TOC3", "Technology and service-stack rationale"),
        ("TOC3", "Delivery-phase configuration refinements"),
        ("TOC2", "3.3 MSP entry, network segmentation, remote access, and security rationale"),
        ("TOC3", "Interface and segment design"),
        ("TOC3", "Policy and exposure model"),
        ("TOC3", "Operational interpretation"),
        ("TOC2", "3.4 Company 1 Services"),
        ("TOC3", "Service overview"),
        ("TOC3", "Architectural rationale"),
        ("TOC3", "Observed operating state"),
        ("TOC3", "Service composition and operational reading"),
        ("TOC2", "3.5 Company 2 identity, shared forest context, DNS, and DHCP"),
        ("TOC3", "Identity service health"),
        ("TOC3", "Namespace and forest design"),
        ("TOC2", "3.6 Storage, file services, and isolated SAN design"),
        ("TOC3", "File-service state"),
        ("TOC3", "SAN isolation model"),
        ("TOC3", "Share presentation model"),
        ("TOC2", "3.7 Client access, identity validation, and dual-hostname web delivery"),
        ("TOC3", "Client validation perspectives"),
        ("TOC3", "Client resolver and share-consumption alignment"),
        ("TOC3", "Hostname-based web publishing behavior"),
        ("TOC3", "Client-service interpretation"),
        ("TOC2", "3.8 Backup, recovery, and offsite protection"),
        ("TOC3", "Backup design basis"),
        ("TOC3", "Inter-site backup path"),
        ("TOC3", "Delivery-phase backup and credential refinements"),
        ("TOC3", "Current operational state"),
        ("TOC3", "Recovery role in the overall site design"),
        ("TOC2", "3.9 Requirement-to-implementation traceability"),
        ("TOC2", "3.10 Service dependency, failure domains, and access model"),
        ("TOC3", "Dependency view"),
        ("TOC3", "Access model interpretation"),
        ("TOC2", "3.11 Storage, backup, and recovery flow"),
        ("TOC3", "Data-protection layers"),
        ("TOC3", "Sync versus backup"),
        ("TOC2", "3.12 Maintenance and daily duties"),
        ("TOC3", "Routine operational checks"),
        ("TOC2", "3.13 Troubleshooting and fast triage guide"),
        ("TOC3", "Fast triage principles"),
        ("TOC2", "3.14 Integrated design summary"),
        ("TOC1", "4. Conclusion"),
        ("TOC1", "5. Appendices"),
        ("TOC2", "Appendix A. Observed addressing, gateways, and endpoints"),
        ("TOC2", "Appendix B. Evidence and reference traceability"),
        ("TOC2", "Appendix C. Service verification matrix"),
        ("TOC1", "6. References"),
    ]

    insert_at = body.index(list_of_figures_heading)
    for offset, (style, text) in enumerate(toc_entries):
        body.insert(insert_at + offset, make_paragraph(text, style))

    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone="yes")


def rewrite_docx(source, destination):
    with ZipFile(source, "r") as zin:
        document_xml = patch_document_xml(zin.read("word/document.xml"))
        with ZipFile(destination, "w", compression=ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = document_xml if item.filename == "word/document.xml" else zin.read(item.filename)
                zout.writestr(item, data)


def main():
    for output in OUTPUTS:
        rewrite_docx(SOURCE, output)
        print(output)


if __name__ == "__main__":
    main()
