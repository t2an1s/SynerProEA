//+------------------------------------------------------------------+
//| SynPropEA_FileComm.mqh                                           |
//| Contains file communication functions for SynPropEA system       |
//+------------------------------------------------------------------+

// Command types
#define CMD_OPEN_LONG "OPEN_LONG"
#define CMD_OPEN_SHORT "OPEN_SHORT"
#define CMD_CLOSE_LONG "CLOSE_LONG" 
#define CMD_CLOSE_SHORT "CLOSE_SHORT"
#define CMD_MODIFY_SLTP "MODIFY_SLTP"
#define CMD_CLOSE_PARTIAL "CLOSE_PARTIAL"

//+------------------------------------------------------------------+
//| Write a command to the common file                               |
//+------------------------------------------------------------------+
bool WriteCommandToFile(string file_name, string command, string symbol, double lots=0, double sl=0, double tp=0, string comment="")
{
    int file_handle = FileOpen(file_name, FILE_WRITE|FILE_CSV|FILE_ANSI);
    if (file_handle == INVALID_HANDLE) {
        Print("ERROR: Cannot open command file for writing. Error: ", GetLastError());
        return false;
    }
    
    string cmd_line = command + "," + symbol + "," + 
                     DoubleToString(lots, 2) + "," + 
                     DoubleToString(sl, 5) + "," + 
                     DoubleToString(tp, 5) + "," + 
                     comment;
    
    FileWriteString(file_handle, cmd_line + "\n");
    FileClose(file_handle);
    
    Print("Command written to file: ", cmd_line);
    return true;
}

//+------------------------------------------------------------------+
//| Send an open trade command                                        |
//+------------------------------------------------------------------+
bool SendOpenTradeCommand(string file_name, bool is_buy, string symbol, double lots, double sl_price, double tp_price, string comment="")
{
    string cmd = is_buy ? CMD_OPEN_LONG : CMD_OPEN_SHORT;
    return WriteCommandToFile(file_name, cmd, symbol, lots, sl_price, tp_price, comment);
}

//+------------------------------------------------------------------+
//| Send a close trade command                                        |
//+------------------------------------------------------------------+
bool SendCloseTradeCommand(string file_name, bool is_buy, string symbol)
{
    string cmd = is_buy ? CMD_CLOSE_LONG : CMD_CLOSE_SHORT;
    return WriteCommandToFile(file_name, cmd, symbol);
}

//+------------------------------------------------------------------+
//| Send a modify SL/TP command                                       |
//+------------------------------------------------------------------+
bool SendModifySLTPCommand(string file_name, string symbol, double sl_price, double tp_price)
{
    return WriteCommandToFile(file_name, CMD_MODIFY_SLTP, symbol, 0, sl_price, tp_price);
}

//+------------------------------------------------------------------+
//| Send a partial close command                                      |
//+------------------------------------------------------------------+
bool SendClosePartialCommand(string file_name, string symbol, double lots_to_close)
{
    return WriteCommandToFile(file_name, CMD_CLOSE_PARTIAL, symbol, lots_to_close);
}

//+------------------------------------------------------------------+
//| Read slave status file and extract data                           |
//+------------------------------------------------------------------+
bool ReadSlaveStatus(string file_name, double &balance, double &equity, double &daily_pnl, int &account_id, string &timestamp)
{
    if (!FileIsExist(file_name)) {
        Print("Slave status file does not exist: ", file_name);
        return false;
    }
    
    int file_handle = FileOpen(file_name, FILE_READ|FILE_TXT|FILE_ANSI);
    if (file_handle == INVALID_HANDLE) {
        Print("ERROR: Cannot open slave status file for reading. Error: ", GetLastError());
        return false;
    }
    
    // Initialize default values
    balance = 0.0;
    equity = 0.0;
    daily_pnl = 0.0;
    account_id = 0;
    timestamp = "";
    
    // Read the file line by line
    while (!FileIsEnding(file_handle)) {
        string line = FileReadString(file_handle);
        string parts[];
        
        StringSplit(line, '=', parts);
        if (ArraySize(parts) != 2) continue; // Skip malformed lines
        
        string key = parts[0];
        string value = parts[1];
        
        if (key == "ACCOUNT_BALANCE") balance = StringToDouble(value);
        else if (key == "ACCOUNT_EQUITY") equity = StringToDouble(value);
        else if (key == "DAILY_PNL") daily_pnl = StringToDouble(value);
        else if (key == "ACCOUNT_ID") account_id = (int)StringToInteger(value);
        else if (key == "TIMESTAMP") timestamp = value;
    }
    
    FileClose(file_handle);
    return true;
}
