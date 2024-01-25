# PowerShell Remote Assistance Script
Overview
This PowerShell script streamlines the utilization of the msra tool within older Windows domains, especially during network domain migrations. The script simplifies user interaction by prompting for credentials only once and securely storing them for subsequent use. By remaining open, it eliminates the need to re-enter credentials, offering an efficient solution for medium to large network environments.

## Usage
Constants Modification: Update the global constants (Server, Old Domain, New Domain, OU to Test) to match your environment.

Execution: Run the script and follow the prompts to provide the remote computer name.

Automated Remote Assistance: The script automates the initiation of Remote Assistance based on the domain of the specified remote computer.

Feel free to customize the script according to your specific needs.
