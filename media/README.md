# Architecture Diagram

To create the architecture diagram (`architecture.png`), you can use:

## Option 1: Draw.io / Diagrams.net (Recommended)
1. Go to https://app.diagrams.net/
2. Create a new diagram
3. Use Azure icon library: Click **More Shapes** → Search "Azure" → Enable **Azure** library
4. Drag and drop these Azure icons:
   - Virtual Network (with 3 subnets)
   - Application Gateway
   - Container Apps
   - Container Registry
   - Private Endpoint
5. Add connections showing the traffic flow
6. Export as PNG: **File** → **Export as** → **PNG** (recommended: 2x or 3x scale for high quality)
7. Save as `architecture.png` in this directory

## Option 2: Microsoft Visio
1. Use Azure architecture stencils: https://learn.microsoft.com/azure/architecture/icons/
2. Download Azure icons
3. Create diagram with:
   - Virtual Network containing subnets
   - Application Gateway in subnet 10.0.3.0/24
   - Container Apps in subnet 10.0.0.0/23
   - Private Endpoint in subnet 10.0.2.0/24
   - Container Registry with private connection
4. Export as PNG

## Option 3: PowerPoint with Azure Icons
1. Download Azure icons: https://learn.microsoft.com/azure/architecture/icons/
2. Create a slide with the architecture
3. Save as PNG (high resolution)

## Reference Example
See: https://github.com/dmauser/azure-virtualwan/blob/main/svh-ri-intra-region/media/networkdiagram.png

## Diagram Requirements
- Show Internet → Application Gateway → Container Apps → ACR flow
- Display subnet CIDRs (10.0.3.0/24, 10.0.0.0/23, 10.0.2.0/24)
- Indicate HTTPS backend connection
- Show private endpoint connectivity
- Use official Azure icons for professional appearance
- Recommended size: 1200-1600px width for GitHub display
