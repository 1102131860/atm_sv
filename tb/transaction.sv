//////////////////////////////////////////////////////////////////////////
// This file include all the Transcation (Data) for the whole test systems
//////////////////////////////////////////////////////////////////////////

// abstract class (cannot be initialized)
virtual class BaseTr;
    static int count;
    int id;
    function new();
        id = count++;
    endfunction
    // pure virtual functions
    pure virtual function bit compare(input BaseTr to);
    pure virtual function BaseTr copy(input BaseTr to=null);
    pure virtual function void display(input string prefix="");
endclass

// A label for UNI_cell class to refer
typedef class NNI_cell;

// UNI_cell class
class UNI_cell extends BaseTr;
    // Physical fields
    // Use bit type for stable simualtion
    rand bit        [ 3:0] GFC;
    rand bit        [ 7:0] VPI;
    rand bit        [15:0] VCI;
    rand bit               CLP;
    rand bit        [ 2:0] PT;
         bit        [ 7:0] HEC;
    rand bit [0:47] [ 7:0] Payload;
    
    function new();
        // nothing to do here
    endfunction : new

    // Compute the HEC value after all other data has been chosen
    function void post_randomize();
        HEC = util_pkg::hec({GFC, VPI, VCI, CLP, PT});
    endfunction : post_randomize

    // @Override
    // Compare this cell with another
    // This could be imporved by telling what field mismatched
    function bit compare(input BaseTr to);
        UNI_cell c;
        `SV_CAST_CHECK($cast(c, to));                       // down cast
        return (GFC == c.GFC) && (VPI == c.VPI) &&
               (VCI == c.VCI) && (CLP == c.CLP) &&
               (PT  == c.PT)  && (HEC == c.HEC) &&
               (Payload == c.Payload);
    endfunction : compare

    // @Override
    // Print a "pretty" version of this object
    function void display(input string prefix="");
        data_pkg::ATMCellType p;
        pack(p);
        $display("%sUNI id:%0d GFC=%x, VPI=%x, VCI=%x, CLP=%b, PT=%x, HEC=%x, Payload[0]=%x",
                 prefix, id, GFC, VPI, VCI, CLP, PT, HEC, Payload[0]);
        $write("%s", prefix);
        foreach (p.Mem[i])
            $write("%x ", p.Mem[i]);
        $display();
    endfunction : display

    // @Override
    // Make a copy of this object
    function BaseTr copy(input BaseTr to=null);
        UNI_cell c;
        if (to == null) c = new();
        else            `SV_CAST_CHECK($cast(c, to));   // down cast
        c.GFC     = GFC;
        c.VPI     = VPI;
        c.VCI     = VCI;
        c.CLP     = CLP;
        c.PT      = PT;
        c.HEC     = HEC;
        c.Payload = Payload;
        return c;                                       // up cast
    endfunction : copy

    // Pack this object's properties into a byte array
    function void pack(output data_pkg::ATMCellType to);
        to.uni.GFC     = GFC;
        to.uni.VPI     = VPI;
        to.uni.VCI     = VCI;
        to.uni.CLP     = CLP;
        to.uni.PT      = PT;
        to.uni.HEC     = HEC;
        to.uni.Payload = Payload;
    endfunction : pack

    // Unpack a byte array into this object
    function void unpack(input data_pkg::ATMCellType from);
        GFC     = from.uni.GFC;
        VPI     = from.uni.VPI;
        VCI     = from.uni.VCI;
        CLP     = from.uni.CLP;
        PT      = from.uni.PT;
        HEC     = from.uni.HEC;
        Payload = from.uni.Payload;
    endfunction : unpack

    // Generate a NNI cell from an UNI cell - used in scoreboard
    function NNI_cell to_NNI();
        NNI_cell c;
        c = new();
        c.VPI     = VPI;                                // NNI has wider VPI and no GFC
        c.VCI     = VCI;
        c.CLP     = CLP;
        c.PT      = PT;
        c.HEC     = HEC;
        c.Payload = Payload;
        return c;
    endfunction : to_NNI
endclass // UNI_cell

// NNI_cell class
class NNI_cell extends BaseTr;
    // Physical fields
    // Use bit type for stable simualtion
    rand bit        [11:0] VPI;
    rand bit        [15:0] VCI;
    rand bit               CLP;
    rand bit        [ 2:0] PT;
         bit        [ 7:0] HEC;
    rand bit [0:47] [ 7:0] Payload;
    
    function new();
        // nothing to do here
    endfunction : new

    // @Override
    // Compare this cell with another
    // This could be imporved by telling what field mismatched
    function bit compare(input BaseTr to);
        NNI_cell c;
        `SV_CAST_CHECK($cast(c, to));                       // down cast
        return (VPI == c.VPI) && (VCI == c.VCI) &&
               (CLP == c.CLP) && (PT  == c.PT)  &&
               (HEC == c.HEC) && (Payload == c.Payload);
    endfunction : compare

    // @Override
    // Print a "pretty" version of this object
    function void display(input string prefix="");
        data_pkg::ATMCellType p;
        pack(p);
        $display("%sNNI id:%0d, VPI=%x, VCI=%x, CLP=%b, PT=%x, HEC=%x, Payload[0]=%x",
                 prefix, id, VPI, VCI, CLP, PT, HEC, Payload[0]);
        $write("%s", prefix);
        foreach (p.Mem[i])
            $write("%x ", p.Mem[i]);
        $display();
    endfunction : display

    // @Override
    // Make a copy of this object
    function BaseTr copy(input BaseTr to=null);
        NNI_cell c;
        if (to == null) c = new();
        else            `SV_CAST_CHECK($cast(c, to));   // down cast
        c.VPI     = VPI;
        c.VCI     = VCI;
        c.CLP     = CLP;
        c.PT      = PT;
        c.HEC     = HEC;
        c.Payload = Payload;
        return c;                                       // up cast
    endfunction : copy

    // Pack this object's properties into a byte array
    function void pack(output data_pkg::ATMCellType to);
        to.nni.VPI     = VPI;
        to.nni.VCI     = VCI;
        to.nni.CLP     = CLP;
        to.nni.PT      = PT;
        to.nni.HEC     = HEC;
        to.nni.Payload = Payload;
    endfunction : pack

    // Unpack a byte array into this object
    function void unpack(input data_pkg::ATMCellType from);
        VPI     = from.nni.VPI;
        VCI     = from.nni.VCI;
        CLP     = from.nni.CLP;
        PT      = from.nni.PT;
        HEC     = from.nni.HEC;
        Payload = from.nni.Payload;
    endfunction : unpack
endclass // NNI_cell
