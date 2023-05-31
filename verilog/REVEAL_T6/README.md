PLEASE READ FOLLOWING DOCUMENT CAREFULLY. THIS IS IMPORTANT INFORMATION FOR GITHUB COLLABORATION  
We are trying to follow the REVISION CONTROL method recommended by xilinx  
https://www.xilinx.com/video/hardware/vivado-design-suite-revision-control.html  

---

##################################  
CREATE / INCLUDE DESIGN SOURCE  
#################################  
TOP level code is Reveal_Top.v  
Please include codes of other submodules in respective folders  
  
All the design source files(.v files) must be inside ./RTL folder  
  
---  
  
###########INCLUDE############  
If you want to include files from different project to this project follow these steps:  
Step 1: Copy the necessary files from source directory to `./RTL/<correct folder>/`
        DO NOT create files directly in ./RTL directory  
        **Top.v** should be the only design file in ./RTL folder Everything else should be in corrosponding dirctories  
Step 2: Click Add Sources in the GUI top Left corner  
Step 3: Add or create design sources. Press Next  
Step 4: Add Files/Directories. Choose the file from `./RTL/<file location>`. DO NOT choose files which are not in ./RTL/*. If you want to add files outside ./RTL/* follow Step 1  
Step 5: **IMPORTANT** Make sure the checkbox "Copy sources into project" is NOT selected. Prese Finish  
  
###########CREATE############  
If you want to create a new .v file please follow these steps:  
Step 1: Click "Add sources" from file>Add sources or Add sources button from top left corner of the GUI  
Step 2: Add or create design sources. Press Next  
Step 3: Click "Create File"  
Step 4: File type: Verilog  
        File name: whatever_you_want.v  
        File location: **IMPORTANT** Make sure you choose the folder under ./RTL/* By Default it will show `<Local to Project>`. Do NOT use `<Local to Project>` if you do that your code will not be uploaded on github. Do NOT create any files directly in `./RTL` dirctory. All the RTL files(except Reveal_Top.v) MUST be placed in correct subfolders.  
  
##################################  
CREATE IP SOURCE  
#################################  
All the IPs MUST be generated in ./IP/ dirctory. The IPs generated outside this directory will not be uploaded to github.  
Step 1: Open IP Catalog.   
Step 2: Choose the IP that you want to generate  
Step 3: **IMPORTANT** You MUST select correct "IP Location". Click "IP Location" tab from the menu bar of Customize IP windows. Choose the ./IP or `./IP/<correct_subdirectory>` from explorer.  
Step 4: Configure IP according to your requirements  
Step 5: Press OK  
  
  
  
  
  