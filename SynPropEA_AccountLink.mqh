//+------------------------------------------------------------------+
//|                                           SynPropEA_AccountLink.mqh |
//|                                                              t2an1s |
//|                                  https://github.com/t2an1s/SynerProEA |
//+------------------------------------------------------------------+
#property copyright "t2an1s"
#property link      "https://github.com/t2an1s/SynerProEA"

// File name for account linking
#define ACCOUNT_LINK_FILENAME "SynPropEA_AccountLink.txt"

// Structure to hold account link data
struct AccountLinkData {
    long master_account;
    string master_server;
    long slave_account;
    string slave_server;
};

// Global array to store account links
static AccountLinkData g_account_links[];

//+------------------------------------------------------------------+
//| Create account linking file if it doesn't exist                    |
//+------------------------------------------------------------------+
bool CreateAccountLinkFile(const int magic_number) {
    PrintFormat("CreateAccountLinkFile called with magic_number: %d", magic_number);
    
    int file_handle = FileOpen(ACCOUNT_LINK_FILENAME, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ",");
    if(file_handle == INVALID_HANDLE) {
        PrintFormat("CreateAccountLinkFile: Error creating account link file. Error: %d", GetLastError());
        return false;
    }
    
    // Get current account info
    long current_account = AccountInfoInteger(ACCOUNT_LOGIN);
    string current_server = AccountInfoString(ACCOUNT_SERVER);
    
    PrintFormat("Current Account Info - Account: %d, Server: %s", current_account, current_server);
    
    // Write default link based on EA magic numbers
    if(magic_number == 12345) { // Master EA
        FileWrite(file_handle, 
                 IntegerToString(current_account),  // Master account
                 current_server,                    // Master server
                 "0",                              // Slave account (to be filled)
                 current_server);                  // Slave server
        PrintFormat("CreateAccountLinkFile: Created with Master account %d@%s", current_account, current_server);
    }
    else if(magic_number == 67890) { // Slave EA
        FileWrite(file_handle, 
                 "0",                              // Master account (to be filled)
                 current_server,                   // Master server
                 IntegerToString(current_account), // Slave account
                 current_server);                  // Slave server
        PrintFormat("CreateAccountLinkFile: Created with Slave account %d@%s", current_account, current_server);
    }
    else {
        FileWrite(file_handle, "0", current_server, "0", current_server); // Default empty link
        PrintFormat("CreateAccountLinkFile: Created with empty link (unknown EA type: %d)", magic_number);
    }
    
    FileClose(file_handle);
    return true;
}

//+------------------------------------------------------------------+
//| Initialize account linking                                         |
//+------------------------------------------------------------------+
bool InitializeAccountLinks() {
    ArrayFree(g_account_links);
    
    // Try to create file if it doesn't exist
    if(!CreateAccountLinkFile(0)) {
        return false;
    }
    
    int file_handle = FileOpen(ACCOUNT_LINK_FILENAME, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, ",");
    if(file_handle == INVALID_HANDLE) {
        Print("InitializeAccountLinks: Error opening account link file. Error: ", GetLastError());
        return false;
    }
    
    while(!FileIsEnding(file_handle)) {
        string master_acc_str = FileReadString(file_handle);
        string master_srv = FileReadString(file_handle);
        string slave_acc_str = FileReadString(file_handle);
        string slave_srv = FileReadString(file_handle);
        
        if(!FileIsLineEnding(file_handle) && !FileIsEnding(file_handle)) {
            Print("InitializeAccountLinks: Invalid line format in account link file.");
            continue;
        }
        
        // Skip empty or invalid links
        if(master_acc_str == "" || slave_acc_str == "" || 
           StringToInteger(master_acc_str) == 0 || StringToInteger(slave_acc_str) == 0) {
            continue;
        }
        
        int current_size = ArraySize(g_account_links);
        ArrayResize(g_account_links, current_size + 1);
        g_account_links[current_size].master_account = StringToInteger(master_acc_str);
        g_account_links[current_size].master_server = master_srv;
        g_account_links[current_size].slave_account = StringToInteger(slave_acc_str);
        g_account_links[current_size].slave_server = slave_srv;
        
        PrintFormat("InitializeAccountLinks: Loaded link - Master: %d (%s), Slave: %d (%s)", 
                   g_account_links[current_size].master_account,
                   g_account_links[current_size].master_server,
                   g_account_links[current_size].slave_account,
                   g_account_links[current_size].slave_server);
    }
    
    FileClose(file_handle);
    return true;
}

//+------------------------------------------------------------------+
//| Check if account is linked and initialize if needed                 |
//+------------------------------------------------------------------+
bool IsAccountLinked(const long account_number, const string server, const int magic_number) {
    PrintFormat("IsAccountLinked called with Account: %d, Server: '%s', Magic: %d", account_number, server, magic_number);
    
    // Try to create file if it doesn't exist
    if(!FileIsExist(ACCOUNT_LINK_FILENAME, FILE_COMMON)) {
        PrintFormat("Account link file '%s' doesn't exist in common folder, creating...", ACCOUNT_LINK_FILENAME);
        if(!CreateAccountLinkFile(magic_number)) {
            Print("Failed to create account link file!");
            return false;
        }
    }
    
    // Read and parse the link file
    int file_handle = FileOpen(ACCOUNT_LINK_FILENAME, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, ",");
    if(file_handle == INVALID_HANDLE) {
        PrintFormat("IsAccountLinked: Error opening account link file. Error: %d", GetLastError());
        return false;
    }
    
    // Clear existing links
    ArrayFree(g_account_links);
    
    // Read all links from file
    bool found_link = false;
    while(!FileIsEnding(file_handle)) {
        AccountLinkData link;
        
        string master_acc_str = FileReadString(file_handle);
        link.master_server = FileReadString(file_handle);
        string slave_acc_str = FileReadString(file_handle);
        link.slave_server = FileReadString(file_handle);
        
        // Convert account numbers, handling empty or invalid strings
        link.master_account = StringToInteger(master_acc_str);
        link.slave_account = StringToInteger(slave_acc_str);
        
        PrintFormat("Read link - Master: %d@%s, Slave: %d@%s", 
                   link.master_account, link.master_server,
                   link.slave_account, link.slave_server);
        
        // Skip invalid or empty links
        if(link.master_account == 0 && link.slave_account == 0) {
            Print("Found empty link, continuing...");
            continue;
        }
        
        // If this is a new EA installation and we have a magic number
        if(magic_number > 0) {
            if(magic_number == 12345 && link.master_account == 0) { // Master EA finding empty master slot
                PrintFormat("Master EA (%d) found empty master slot, updating with account %d@%s", 
                          magic_number, account_number, server);
                // Update the file with master info
                FileClose(file_handle);
                UpdateLinkFile(account_number, server, link.slave_account, link.slave_server);
                return true;
            }
            else if(magic_number == 67890 && link.slave_account == 0) { // Slave EA finding empty slave slot
                PrintFormat("Slave EA (%d) found empty slave slot, updating with account %d@%s", 
                          magic_number, account_number, server);
                // Update the file with slave info
                FileClose(file_handle);
                UpdateLinkFile(link.master_account, link.master_server, account_number, server);
                return true;
            }
        }
        
        // Check if this account is in any existing link
        if(account_number == link.master_account && server == link.master_server) {
            PrintFormat("Found matching master account %d@%s", account_number, server);
            found_link = true;
        }
        else if(account_number == link.slave_account && server == link.slave_server) {
            PrintFormat("Found matching slave account %d@%s", account_number, server);
            found_link = true;
        }
        
        // Store valid links
        int size = ArraySize(g_account_links);
        ArrayResize(g_account_links, size + 1);
        g_account_links[size] = link;
    }
    
    FileClose(file_handle);
    
    if(!found_link) {
        PrintFormat("No matching link found for account %d@%s with magic %d", 
                   account_number, server, magic_number);
    }
    return found_link;
}

//+------------------------------------------------------------------+
//| Update the link file with new account information                  |
//+------------------------------------------------------------------+
bool UpdateLinkFile(const long master_account, const string master_server, 
                   const long slave_account, const string slave_server) {
    PrintFormat("UpdateLinkFile called - Master: %d@%s, Slave: %d@%s", 
               master_account, master_server, slave_account, slave_server);
               
    int file_handle = FileOpen(ACCOUNT_LINK_FILENAME, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ",");
    if(file_handle == INVALID_HANDLE) {
        PrintFormat("UpdateLinkFile: Error opening file for writing. Error: %d", GetLastError());
        return false;
    }
    
    FileWrite(file_handle,
             IntegerToString(master_account),
             master_server,
             IntegerToString(slave_account),
             slave_server);
             
    FileClose(file_handle);
    PrintFormat("UpdateLinkFile: Successfully updated link file with Master: %d@%s, Slave: %d@%s", 
               master_account, master_server, slave_account, slave_server);
    return true;
}

//+------------------------------------------------------------------+
//| Get linked account number                                          |
//+------------------------------------------------------------------+
long GetLinkedAccount(long account_number, string server) {
    static bool links_initialized = false;
    
    if(!links_initialized) {
        links_initialized = InitializeAccountLinks();
    }
    
    for(int i = 0; i < ArraySize(g_account_links); i++) {
        // If this is a master account, return its slave
        if(g_account_links[i].master_account == account_number && 
           g_account_links[i].master_server == server) {
            return g_account_links[i].slave_account;
        }
        // If this is a slave account, return its master
        if(g_account_links[i].slave_account == account_number && 
           g_account_links[i].slave_server == server) {
            return g_account_links[i].master_account;
        }
    }
    
    return 0; // Return 0 if no linked account found
}

//+------------------------------------------------------------------+
//| Get linked server name                                             |
//+------------------------------------------------------------------+
string GetLinkedServer(long account_number, string server) {
    static bool links_initialized = false;
    
    if(!links_initialized) {
        links_initialized = InitializeAccountLinks();
    }
    
    for(int i = 0; i < ArraySize(g_account_links); i++) {
        // If this is a master account, return slave server
        if(g_account_links[i].master_account == account_number && 
           g_account_links[i].master_server == server) {
            return g_account_links[i].slave_server;
        }
        // If this is a slave account, return master server
        if(g_account_links[i].slave_account == account_number && 
           g_account_links[i].slave_server == server) {
            return g_account_links[i].master_server;
        }
    }
    
    return ""; // Return empty string if no linked server found
} 
