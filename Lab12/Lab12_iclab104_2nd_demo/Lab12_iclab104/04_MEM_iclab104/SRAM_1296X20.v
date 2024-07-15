/*******************************************************************************

             Synchronous Dual Port SRAM Compiler 

                   UMC 0.18um Generic Logic Process 
   __________________________________________________________________________


       (C) Copyright 2002-2009 Faraday Technology Corp. All Rights Reserved.

     This source code is an unpublished work belongs to Faraday Technology
     Corp.  It is considered a trade secret and is not to be divulged or
     used by parties who have not received written authorization from
     Faraday Technology Corp.

     Faraday's home page can be found at:
     http://www.faraday-tech.com/
    
________________________________________________________________________________

      Module Name       :  SRAM_1296X20  
      Word              :  1296          
      Bit               :  20            
      Byte              :  1             
      Mux               :  1             
      Power Ring Type   :  port          
      Power Ring Width  :  2 (um)        
      Output Loading    :  0.05 (pf)     
      Input Data Slew   :  0.02 (ns)     
      Input Clock Slew  :  0.02 (ns)     

________________________________________________________________________________

      Library          : FSA0M_A
      Memaker          : 200901.2.1
      Date             : 2023/10/20 23:57:45

________________________________________________________________________________


   Notice on usage: Fixed delay or timing data are given in this model.
                    It supports SDF back-annotation, please generate SDF file
                    by EDA tools to get the accurate timing.

 |-----------------------------------------------------------------------------|

   Warning : If customer's design viloate the set-up time or hold time criteria 
   of synchronous SRAM, it's possible to hit the meta-stable point of 
   latch circuit in the decoder and cause the data loss in the memory bitcell.
   So please follow the memory IP's spec to design your product.

 |-----------------------------------------------------------------------------|

                Library          : FSA0M_A
                Memaker          : 200901.2.1
                Date             : 2023/10/20 23:57:45

 *******************************************************************************/

`resetall
`timescale 10ps/1ps


module SRAM_1296X20 (A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,B0,B1,B2,B3,B4,
                     B5,B6,B7,B8,B9,B10,DOA0,DOA1,DOA2,DOA3,DOA4,
                     DOA5,DOA6,DOA7,DOA8,DOA9,DOA10,DOA11,DOA12,
                     DOA13,DOA14,DOA15,DOA16,DOA17,DOA18,DOA19,
                     DOB0,DOB1,DOB2,DOB3,DOB4,DOB5,DOB6,DOB7,
                     DOB8,DOB9,DOB10,DOB11,DOB12,DOB13,DOB14,
                     DOB15,DOB16,DOB17,DOB18,DOB19,DIA0,DIA1,
                     DIA2,DIA3,DIA4,DIA5,DIA6,DIA7,DIA8,DIA9,
                     DIA10,DIA11,DIA12,DIA13,DIA14,DIA15,DIA16,
                     DIA17,DIA18,DIA19,DIB0,DIB1,DIB2,DIB3,
                     DIB4,DIB5,DIB6,DIB7,DIB8,DIB9,DIB10,DIB11,
                     DIB12,DIB13,DIB14,DIB15,DIB16,DIB17,DIB18,
                     DIB19,WEAN,WEBN,CKA,CKB,CSA,CSB,OEA,OEB);

  `define    TRUE                 (1'b1)              
  `define    FALSE                (1'b0)              

  parameter  SYN_CS               = `TRUE;            
  parameter  NO_SER_TOH           = `TRUE;            
  parameter  AddressSize          = 11;               
  parameter  Bits                 = 20;               
  parameter  Words                = 1296;             
  parameter  Bytes                = 1;                
  parameter  AspectRatio          = 1;                
  parameter  Tr2w                 = (184:264:433);    
  parameter  Tw2r                 = (171:240:386);    
  parameter  TOH                  = (61:88:144);      

  output     DOA0,DOA1,DOA2,DOA3,DOA4,DOA5,DOA6,DOA7,DOA8,
             DOA9,DOA10,DOA11,DOA12,DOA13,DOA14,DOA15,DOA16,DOA17,DOA18,
             DOA19;
  output     DOB0,DOB1,DOB2,DOB3,DOB4,DOB5,DOB6,DOB7,DOB8,
             DOB9,DOB10,DOB11,DOB12,DOB13,DOB14,DOB15,DOB16,DOB17,DOB18,
             DOB19;
  input      DIA0,DIA1,DIA2,DIA3,DIA4,DIA5,DIA6,DIA7,DIA8,
             DIA9,DIA10,DIA11,DIA12,DIA13,DIA14,DIA15,DIA16,DIA17,DIA18,
             DIA19;
  input      DIB0,DIB1,DIB2,DIB3,DIB4,DIB5,DIB6,DIB7,DIB8,
             DIB9,DIB10,DIB11,DIB12,DIB13,DIB14,DIB15,DIB16,DIB17,DIB18,
             DIB19;
  input      A0,A1,A2,A3,A4,A5,A6,A7,A8,
             A9,A10;
  input      B0,B1,B2,B3,B4,B5,B6,B7,B8,
             B9,B10;
  input      OEA;                                     
  input      OEB;                                     
  input      WEAN;                                    
  input      WEBN;                                    
  input      CKA;                                     
  input      CKB;                                     
  input      CSA;                                     
  input      CSB;                                     

`protect
  reg        [Bits-1:0]           Memory [Words-1:0];           

  wire       [Bytes*Bits-1:0]     DOA_;               
  wire       [Bytes*Bits-1:0]     DOB_;               
  wire       [AddressSize-1:0]    A_;                 
  wire       [AddressSize-1:0]    B_;                 
  wire                            OEA_;               
  wire                            OEB_;               
  wire       [Bits-1:0]           DIA_;               
  wire       [Bits-1:0]           DIB_;               
  wire                            WEBN_;              
  wire                            WEAN_;              
  wire                            CKA_;               
  wire                            CKB_;               
  wire                            CSA_;               
  wire                            CSB_;               

  wire                            con_A;              
  wire                            con_B;              
  wire                            con_DIA;            
  wire                            con_DIB;            
  wire                            con_CKA;            
  wire                            con_CKB;            
  wire                            con_WEBN;           
  wire                            con_WEAN;           

  reg        [AddressSize-1:0]    Latch_A;            
  reg        [AddressSize-1:0]    Latch_B;            
  reg        [Bits-1:0]           Latch_DIA;          
  reg        [Bits-1:0]           Latch_DIB;          
  reg                             Latch_WEAN;         
  reg                             Latch_WEBN;         
  reg                             Latch_CSA;          
  reg                             Latch_CSB;          
  reg        [AddressSize-1:0]    LastCycleAAddress;  
  reg        [AddressSize-1:0]    LastCycleBAddress;  

  reg        [AddressSize-1:0]    A_i;                
  reg        [AddressSize-1:0]    B_i;                
  reg        [Bits-1:0]           DIA_i;              
  reg        [Bits-1:0]           DIB_i;              
  reg                             WEAN_i;             
  reg                             WEBN_i;             
  reg                             CSA_i;              
  reg                             CSB_i;              

  reg                             n_flag_A0;          
  reg                             n_flag_A1;          
  reg                             n_flag_A2;          
  reg                             n_flag_A3;          
  reg                             n_flag_A4;          
  reg                             n_flag_A5;          
  reg                             n_flag_A6;          
  reg                             n_flag_A7;          
  reg                             n_flag_A8;          
  reg                             n_flag_A9;          
  reg                             n_flag_A10;         
  reg                             n_flag_B0;          
  reg                             n_flag_B1;          
  reg                             n_flag_B2;          
  reg                             n_flag_B3;          
  reg                             n_flag_B4;          
  reg                             n_flag_B5;          
  reg                             n_flag_B6;          
  reg                             n_flag_B7;          
  reg                             n_flag_B8;          
  reg                             n_flag_B9;          
  reg                             n_flag_B10;         
  reg                             n_flag_DIA0;        
  reg                             n_flag_DIB0;        
  reg                             n_flag_DIA1;        
  reg                             n_flag_DIB1;        
  reg                             n_flag_DIA2;        
  reg                             n_flag_DIB2;        
  reg                             n_flag_DIA3;        
  reg                             n_flag_DIB3;        
  reg                             n_flag_DIA4;        
  reg                             n_flag_DIB4;        
  reg                             n_flag_DIA5;        
  reg                             n_flag_DIB5;        
  reg                             n_flag_DIA6;        
  reg                             n_flag_DIB6;        
  reg                             n_flag_DIA7;        
  reg                             n_flag_DIB7;        
  reg                             n_flag_DIA8;        
  reg                             n_flag_DIB8;        
  reg                             n_flag_DIA9;        
  reg                             n_flag_DIB9;        
  reg                             n_flag_DIA10;       
  reg                             n_flag_DIB10;       
  reg                             n_flag_DIA11;       
  reg                             n_flag_DIB11;       
  reg                             n_flag_DIA12;       
  reg                             n_flag_DIB12;       
  reg                             n_flag_DIA13;       
  reg                             n_flag_DIB13;       
  reg                             n_flag_DIA14;       
  reg                             n_flag_DIB14;       
  reg                             n_flag_DIA15;       
  reg                             n_flag_DIB15;       
  reg                             n_flag_DIA16;       
  reg                             n_flag_DIB16;       
  reg                             n_flag_DIA17;       
  reg                             n_flag_DIB17;       
  reg                             n_flag_DIA18;       
  reg                             n_flag_DIB18;       
  reg                             n_flag_DIA19;       
  reg                             n_flag_DIB19;       
  reg                             n_flag_WEAN;        
  reg                             n_flag_WEBN;        
  reg                             n_flag_CSA;         
  reg                             n_flag_CSB;         
  reg                             n_flag_CKA_PER;     
  reg                             n_flag_CKA_MINH;    
  reg                             n_flag_CKA_MINL;    
  reg                             n_flag_CKB_PER;     
  reg                             n_flag_CKB_MINH;    
  reg                             n_flag_CKB_MINL;    
  reg                             LAST_n_flag_WEAN;   
  reg                             LAST_n_flag_WEBN;   
  reg                             LAST_n_flag_CSA;    
  reg                             LAST_n_flag_CSB;    
  reg                             LAST_n_flag_CKA_PER;
  reg                             LAST_n_flag_CKA_MINH;
  reg                             LAST_n_flag_CKA_MINL;
  reg                             LAST_n_flag_CKB_PER;
  reg                             LAST_n_flag_CKB_MINH;
  reg                             LAST_n_flag_CKB_MINL;
  reg        [AddressSize-1:0]    NOT_BUS_B;          
  reg        [AddressSize-1:0]    LAST_NOT_BUS_B;     
  reg        [AddressSize-1:0]    NOT_BUS_A;          
  reg        [AddressSize-1:0]    LAST_NOT_BUS_A;     
  reg        [Bits-1:0]           NOT_BUS_DIA;        
  reg        [Bits-1:0]           NOT_BUS_DIB;        
  reg        [Bits-1:0]           LAST_NOT_BUS_DIA;   
  reg        [Bits-1:0]           LAST_NOT_BUS_DIB;   

  reg        [AddressSize-1:0]    last_A;             
  reg        [AddressSize-1:0]    latch_last_A;       
  reg        [AddressSize-1:0]    last_B;             
  reg        [AddressSize-1:0]    latch_last_B;       

  reg        [Bits-1:0]           last_DIA;           
  reg        [Bits-1:0]           latch_last_DIA;     
  reg        [Bits-1:0]           last_DIB;           
  reg        [Bits-1:0]           latch_last_DIB;     

  reg        [Bits-1:0]           DOA_i;              
  reg        [Bits-1:0]           DOB_i;              

  reg                             LastClkAEdge;       
  reg                             LastClkBEdge;       

  reg                             Last_WEAN_i;        
  reg                             Last_WEBN_i;        

  reg                             flag_A_x;           
  reg                             flag_B_x;           
  reg                             flag_CSA_x;         
  reg                             flag_CSB_x;         
  reg                             NODELAYA;           
  reg                             NODELAYB;           
  reg        [Bits-1:0]           DOA_tmp;            
  reg        [Bits-1:0]           DOB_tmp;            
  event                           EventTOHDOA;        
  event                           EventTOHDOB;        

  time                            Last_tc_ClkA_PosEdge;
  time                            Last_tc_ClkB_PosEdge;

  assign     DOA_                 = {DOA_i};
  assign     DOB_                 = {DOB_i};
  assign     con_A                = CSA_;
  assign     con_B                = CSB_;
  assign     con_DIA              = CSA_ & (!WEAN_);
  assign     con_DIB              = CSB_ & (!WEBN_);
  assign     con_WEAN             = CSA_;
  assign     con_WEBN             = CSB_;
  assign     con_CKA              = CSA_;
  assign     con_CKB              = CSB_;

  bufif1     idoa0           (DOA0, DOA_[0], OEA_);        
  bufif1     idob0           (DOB0, DOB_[0], OEB_);        
  bufif1     idoa1           (DOA1, DOA_[1], OEA_);        
  bufif1     idob1           (DOB1, DOB_[1], OEB_);        
  bufif1     idoa2           (DOA2, DOA_[2], OEA_);        
  bufif1     idob2           (DOB2, DOB_[2], OEB_);        
  bufif1     idoa3           (DOA3, DOA_[3], OEA_);        
  bufif1     idob3           (DOB3, DOB_[3], OEB_);        
  bufif1     idoa4           (DOA4, DOA_[4], OEA_);        
  bufif1     idob4           (DOB4, DOB_[4], OEB_);        
  bufif1     idoa5           (DOA5, DOA_[5], OEA_);        
  bufif1     idob5           (DOB5, DOB_[5], OEB_);        
  bufif1     idoa6           (DOA6, DOA_[6], OEA_);        
  bufif1     idob6           (DOB6, DOB_[6], OEB_);        
  bufif1     idoa7           (DOA7, DOA_[7], OEA_);        
  bufif1     idob7           (DOB7, DOB_[7], OEB_);        
  bufif1     idoa8           (DOA8, DOA_[8], OEA_);        
  bufif1     idob8           (DOB8, DOB_[8], OEB_);        
  bufif1     idoa9           (DOA9, DOA_[9], OEA_);        
  bufif1     idob9           (DOB9, DOB_[9], OEB_);        
  bufif1     idoa10          (DOA10, DOA_[10], OEA_);      
  bufif1     idob10          (DOB10, DOB_[10], OEB_);      
  bufif1     idoa11          (DOA11, DOA_[11], OEA_);      
  bufif1     idob11          (DOB11, DOB_[11], OEB_);      
  bufif1     idoa12          (DOA12, DOA_[12], OEA_);      
  bufif1     idob12          (DOB12, DOB_[12], OEB_);      
  bufif1     idoa13          (DOA13, DOA_[13], OEA_);      
  bufif1     idob13          (DOB13, DOB_[13], OEB_);      
  bufif1     idoa14          (DOA14, DOA_[14], OEA_);      
  bufif1     idob14          (DOB14, DOB_[14], OEB_);      
  bufif1     idoa15          (DOA15, DOA_[15], OEA_);      
  bufif1     idob15          (DOB15, DOB_[15], OEB_);      
  bufif1     idoa16          (DOA16, DOA_[16], OEA_);      
  bufif1     idob16          (DOB16, DOB_[16], OEB_);      
  bufif1     idoa17          (DOA17, DOA_[17], OEA_);      
  bufif1     idob17          (DOB17, DOB_[17], OEB_);      
  bufif1     idoa18          (DOA18, DOA_[18], OEA_);      
  bufif1     idob18          (DOB18, DOB_[18], OEB_);      
  bufif1     idoa19          (DOA19, DOA_[19], OEA_);      
  bufif1     idob19          (DOB19, DOB_[19], OEB_);      
  buf        ia0             (A_[0], A0);                  
  buf        ia1             (A_[1], A1);                  
  buf        ia2             (A_[2], A2);                  
  buf        ia3             (A_[3], A3);                  
  buf        ia4             (A_[4], A4);                  
  buf        ia5             (A_[5], A5);                  
  buf        ia6             (A_[6], A6);                  
  buf        ia7             (A_[7], A7);                  
  buf        ia8             (A_[8], A8);                  
  buf        ia9             (A_[9], A9);                  
  buf        ia10            (A_[10], A10);                
  buf        ib0             (B_[0], B0);                  
  buf        ib1             (B_[1], B1);                  
  buf        ib2             (B_[2], B2);                  
  buf        ib3             (B_[3], B3);                  
  buf        ib4             (B_[4], B4);                  
  buf        ib5             (B_[5], B5);                  
  buf        ib6             (B_[6], B6);                  
  buf        ib7             (B_[7], B7);                  
  buf        ib8             (B_[8], B8);                  
  buf        ib9             (B_[9], B9);                  
  buf        ib10            (B_[10], B10);                
  buf        idia_0          (DIA_[0], DIA0);              
  buf        idib_0          (DIB_[0], DIB0);              
  buf        idia_1          (DIA_[1], DIA1);              
  buf        idib_1          (DIB_[1], DIB1);              
  buf        idia_2          (DIA_[2], DIA2);              
  buf        idib_2          (DIB_[2], DIB2);              
  buf        idia_3          (DIA_[3], DIA3);              
  buf        idib_3          (DIB_[3], DIB3);              
  buf        idia_4          (DIA_[4], DIA4);              
  buf        idib_4          (DIB_[4], DIB4);              
  buf        idia_5          (DIA_[5], DIA5);              
  buf        idib_5          (DIB_[5], DIB5);              
  buf        idia_6          (DIA_[6], DIA6);              
  buf        idib_6          (DIB_[6], DIB6);              
  buf        idia_7          (DIA_[7], DIA7);              
  buf        idib_7          (DIB_[7], DIB7);              
  buf        idia_8          (DIA_[8], DIA8);              
  buf        idib_8          (DIB_[8], DIB8);              
  buf        idia_9          (DIA_[9], DIA9);              
  buf        idib_9          (DIB_[9], DIB9);              
  buf        idia_10         (DIA_[10], DIA10);            
  buf        idib_10         (DIB_[10], DIB10);            
  buf        idia_11         (DIA_[11], DIA11);            
  buf        idib_11         (DIB_[11], DIB11);            
  buf        idia_12         (DIA_[12], DIA12);            
  buf        idib_12         (DIB_[12], DIB12);            
  buf        idia_13         (DIA_[13], DIA13);            
  buf        idib_13         (DIB_[13], DIB13);            
  buf        idia_14         (DIA_[14], DIA14);            
  buf        idib_14         (DIB_[14], DIB14);            
  buf        idia_15         (DIA_[15], DIA15);            
  buf        idib_15         (DIB_[15], DIB15);            
  buf        idia_16         (DIA_[16], DIA16);            
  buf        idib_16         (DIB_[16], DIB16);            
  buf        idia_17         (DIA_[17], DIA17);            
  buf        idib_17         (DIB_[17], DIB17);            
  buf        idia_18         (DIA_[18], DIA18);            
  buf        idib_18         (DIB_[18], DIB18);            
  buf        idia_19         (DIA_[19], DIA19);            
  buf        idib_19         (DIB_[19], DIB19);            
  buf        icka            (CKA_, CKA);                  
  buf        ickb            (CKB_, CKB);                  
  buf        icsa            (CSA_, CSA);                  
  buf        icsb            (CSB_, CSB);                  
  buf        ioea            (OEA_, OEA);                  
  buf        ioeb            (OEB_, OEB);                  
  buf        iwea0           (WEAN_, WEAN);                
  buf        iweb0           (WEBN_, WEBN);                

  initial begin
    $timeformat (-12, 0, " ps", 20);
    flag_A_x = `FALSE;
    flag_B_x = `FALSE;
    NODELAYA = 1'b0;
    NODELAYB = 1'b0;
  end


  always @(CKA_) begin
    casez ({LastClkAEdge,CKA_})
      2'b01:
         begin
           last_A = latch_last_A;
           last_DIA = latch_last_DIA;
           CSA_monitor;
           pre_latch_dataA;
           memory_functionA;
           if (CSA_==1'b1) Last_tc_ClkA_PosEdge = $time;
           latch_last_A = A_;
           latch_last_DIA = DIA_;
         end
      2'b?x:
         begin
           ErrorMessage(0);
           if (CSA_ !== 0) begin
              if (WEAN_ !== 1'b1) begin
                 all_core_xA(9999,1);
              end else begin
                 #0 disable TOHDOA;
                 NODELAYA = 1'b1;
                 DOA_i = {Bits{1'bX}};
              end
           end
         end
    endcase
    LastClkAEdge = CKA_;
  end

  always @(CKB_) begin
    casez ({LastClkBEdge,CKB_})
      2'b01:
         begin
           last_B = latch_last_B;
           last_DIB = latch_last_DIB;
           CSB_monitor;
           pre_latch_dataB;
           memory_functionB;
           if (CSB_==1'b1) Last_tc_ClkB_PosEdge = $time;
           latch_last_B = B_;
           latch_last_DIB = DIB_;
         end
      2'b?x:
         begin
           ErrorMessage(0);
           if (CSB_ !== 0) begin
              if (WEBN_ !== 1'b1) begin
                 all_core_xB(9999,1);
              end else begin
                 #0 disable TOHDOB;
                 NODELAYB = 1'b1;
                 DOB_i = {Bits{1'bX}};
              end
           end
         end
    endcase
    LastClkBEdge = CKB_;
  end

  always @(
           n_flag_A0 or
           n_flag_A1 or
           n_flag_A2 or
           n_flag_A3 or
           n_flag_A4 or
           n_flag_A5 or
           n_flag_A6 or
           n_flag_A7 or
           n_flag_A8 or
           n_flag_A9 or
           n_flag_A10 or
           n_flag_DIA0 or
           n_flag_DIA1 or
           n_flag_DIA2 or
           n_flag_DIA3 or
           n_flag_DIA4 or
           n_flag_DIA5 or
           n_flag_DIA6 or
           n_flag_DIA7 or
           n_flag_DIA8 or
           n_flag_DIA9 or
           n_flag_DIA10 or
           n_flag_DIA11 or
           n_flag_DIA12 or
           n_flag_DIA13 or
           n_flag_DIA14 or
           n_flag_DIA15 or
           n_flag_DIA16 or
           n_flag_DIA17 or
           n_flag_DIA18 or
           n_flag_DIA19 or
           n_flag_WEAN or
           n_flag_CSA or
           n_flag_CKA_PER or
           n_flag_CKA_MINH or
           n_flag_CKA_MINL
          )
     begin
       timingcheck_violationA;
     end

  always @(
           n_flag_B0 or
           n_flag_B1 or
           n_flag_B2 or
           n_flag_B3 or
           n_flag_B4 or
           n_flag_B5 or
           n_flag_B6 or
           n_flag_B7 or
           n_flag_B8 or
           n_flag_B9 or
           n_flag_B10 or
           n_flag_DIB0 or
           n_flag_DIB1 or
           n_flag_DIB2 or
           n_flag_DIB3 or
           n_flag_DIB4 or
           n_flag_DIB5 or
           n_flag_DIB6 or
           n_flag_DIB7 or
           n_flag_DIB8 or
           n_flag_DIB9 or
           n_flag_DIB10 or
           n_flag_DIB11 or
           n_flag_DIB12 or
           n_flag_DIB13 or
           n_flag_DIB14 or
           n_flag_DIB15 or
           n_flag_DIB16 or
           n_flag_DIB17 or
           n_flag_DIB18 or
           n_flag_DIB19 or
           n_flag_WEBN or
           n_flag_CSB or
           n_flag_CKB_PER or
           n_flag_CKB_MINH or
           n_flag_CKB_MINL
          )
     begin
       timingcheck_violationB;
     end


  always @(EventTOHDOA) 
    begin:TOHDOA 
      #TOH 
      NODELAYA <= 1'b0; 
      DOA_i              =  {Bits{1'bX}}; 
      DOA_i              <= DOA_tmp; 
  end 

  always @(EventTOHDOB) 
    begin:TOHDOB 
      #TOH 
      NODELAYB <= 1'b0; 
      DOB_i              =  {Bits{1'bX}}; 
      DOB_i              <= DOB_tmp; 
  end 


  task timingcheck_violationA;
    integer i;
    begin
      // PORT A
      if ((n_flag_CKA_PER  !== LAST_n_flag_CKA_PER)  ||
          (n_flag_CKA_MINH !== LAST_n_flag_CKA_MINH) ||
          (n_flag_CKA_MINL !== LAST_n_flag_CKA_MINL)) begin
          if (CSA_ !== 1'b0) begin
             if (WEAN_ !== 1'b1) begin
                all_core_xA(9999,1);
             end
             else begin
                #0 disable TOHDOA;
                NODELAYA = 1'b1;
                DOA_i = {Bits{1'bX}};
             end
          end
      end
      else begin
          NOT_BUS_A  = {
                         n_flag_A10,
                         n_flag_A9,
                         n_flag_A8,
                         n_flag_A7,
                         n_flag_A6,
                         n_flag_A5,
                         n_flag_A4,
                         n_flag_A3,
                         n_flag_A2,
                         n_flag_A1,
                         n_flag_A0};

          NOT_BUS_DIA  = {
                         n_flag_DIA19,
                         n_flag_DIA18,
                         n_flag_DIA17,
                         n_flag_DIA16,
                         n_flag_DIA15,
                         n_flag_DIA14,
                         n_flag_DIA13,
                         n_flag_DIA12,
                         n_flag_DIA11,
                         n_flag_DIA10,
                         n_flag_DIA9,
                         n_flag_DIA8,
                         n_flag_DIA7,
                         n_flag_DIA6,
                         n_flag_DIA5,
                         n_flag_DIA4,
                         n_flag_DIA3,
                         n_flag_DIA2,
                         n_flag_DIA1,
                         n_flag_DIA0};

          for (i=0; i<AddressSize; i=i+1) begin
             Latch_A[i] = (NOT_BUS_A[i] !== LAST_NOT_BUS_A[i]) ? 1'bx : Latch_A[i];
          end
          for (i=0; i<Bits; i=i+1) begin
             Latch_DIA[i] = (NOT_BUS_DIA[i] !== LAST_NOT_BUS_DIA[i]) ? 1'bx : Latch_DIA[i];
          end
          Latch_CSA  =  (n_flag_CSA  !== LAST_n_flag_CSA)  ? 1'bx : Latch_CSA;
          Latch_WEAN = (n_flag_WEAN !== LAST_n_flag_WEAN)  ? 1'bx : Latch_WEAN;
          memory_functionA;
      end

      LAST_NOT_BUS_A                 = NOT_BUS_A;
      LAST_NOT_BUS_DIA               = NOT_BUS_DIA;
      LAST_n_flag_WEAN               = n_flag_WEAN;
      LAST_n_flag_CSA                = n_flag_CSA;
      LAST_n_flag_CKA_PER            = n_flag_CKA_PER;
      LAST_n_flag_CKA_MINH           = n_flag_CKA_MINH;
      LAST_n_flag_CKA_MINL           = n_flag_CKA_MINL;
    end
  endtask // end timingcheck_violationA;

  task timingcheck_violationB;
    integer i;
    begin
      // PORT B
      if ((n_flag_CKB_PER  !== LAST_n_flag_CKB_PER)  ||
          (n_flag_CKB_MINH !== LAST_n_flag_CKB_MINH) ||
          (n_flag_CKB_MINL !== LAST_n_flag_CKB_MINL)) begin
          if (CSB_ !== 1'b0) begin
             if (WEBN_ !== 1'b1) begin
                all_core_xB(9999,1);
             end
             else begin
                #0 disable TOHDOB;
                NODELAYB = 1'b1;
                DOB_i = {Bits{1'bX}};
             end
          end
      end
      else begin
          NOT_BUS_B  = {
                         n_flag_B10,
                         n_flag_B9,
                         n_flag_B8,
                         n_flag_B7,
                         n_flag_B6,
                         n_flag_B5,
                         n_flag_B4,
                         n_flag_B3,
                         n_flag_B2,
                         n_flag_B1,
                         n_flag_B0};

          NOT_BUS_DIB  = {
                         n_flag_DIB19,
                         n_flag_DIB18,
                         n_flag_DIB17,
                         n_flag_DIB16,
                         n_flag_DIB15,
                         n_flag_DIB14,
                         n_flag_DIB13,
                         n_flag_DIB12,
                         n_flag_DIB11,
                         n_flag_DIB10,
                         n_flag_DIB9,
                         n_flag_DIB8,
                         n_flag_DIB7,
                         n_flag_DIB6,
                         n_flag_DIB5,
                         n_flag_DIB4,
                         n_flag_DIB3,
                         n_flag_DIB2,
                         n_flag_DIB1,
                         n_flag_DIB0};

          for (i=0; i<AddressSize; i=i+1) begin
             Latch_B[i] = (NOT_BUS_B[i] !== LAST_NOT_BUS_B[i]) ? 1'bx : Latch_B[i];
          end
          for (i=0; i<Bits; i=i+1) begin
             Latch_DIB[i] = (NOT_BUS_DIB[i] !== LAST_NOT_BUS_DIB[i]) ? 1'bx : Latch_DIB[i];
          end
          Latch_CSB  =  (n_flag_CSB  !== LAST_n_flag_CSB)  ? 1'bx : Latch_CSB;
          Latch_WEBN = (n_flag_WEBN !== LAST_n_flag_WEBN)  ? 1'bx : Latch_WEBN;
          memory_functionB;
      end

      LAST_NOT_BUS_B                 = NOT_BUS_B;
      LAST_NOT_BUS_DIB               = NOT_BUS_DIB;
      LAST_n_flag_WEBN               = n_flag_WEBN;
      LAST_n_flag_CSB                = n_flag_CSB;
      LAST_n_flag_CKB_PER            = n_flag_CKB_PER;
      LAST_n_flag_CKB_MINH           = n_flag_CKB_MINH;
      LAST_n_flag_CKB_MINL           = n_flag_CKB_MINL;
    end
  endtask // end timingcheck_violationB;

  task pre_latch_dataA;
    begin
      Latch_A                        = A_;
      Latch_DIA                      = DIA_;
      Latch_CSA                      = CSA_;
      Latch_WEAN                     = WEAN_;
    end
  endtask //end pre_latch_dataA

  task pre_latch_dataB;
    begin
      Latch_B                        = B_;
      Latch_DIB                      = DIB_;
      Latch_CSB                      = CSB_;
      Latch_WEBN                     = WEBN_;
    end
  endtask //end pre_latch_dataB

  task memory_functionA;
    begin
      A_i                            = Latch_A;
      DIA_i                          = Latch_DIA;
      WEAN_i                         = Latch_WEAN;
      CSA_i                          = Latch_CSA;

      if (CSA_ == 1'b1) A_monitor;

      casez({WEAN_i,CSA_i})
        2'b11: begin
           if (AddressRangeCheck(A_i)) begin
              if ((A_i == LastCycleBAddress)&&
                  (Last_WEBN_i == 1'b0) &&
                  ($time-Last_tc_ClkB_PosEdge<Tw2r)) begin
                  ErrorMessage(1);
                  #0 disable TOHDOA;
                  NODELAYA = 1'b1;
                  DOA_i = {Bits{1'bX}};
              end else begin
                  if (NO_SER_TOH == `TRUE) begin
                    if (A_i !== last_A) begin
                       NODELAYA = 1'b1;
                       DOA_tmp = Memory[A_i];
                       ->EventTOHDOA;
                    end else begin
                       NODELAYA = 1'b0;
                       DOA_tmp  = Memory[A_i];
                       DOA_i    = DOA_tmp;
                    end
                  end else begin
                    NODELAYA = 1'b1;
                    DOA_tmp = Memory[A_i];
                    ->EventTOHDOA;
                  end
              end
           end
           else begin
                //DOA_i = {Bits{1'bX}};
                #0 disable TOHDOA;
                NODELAYA = 1'b1;
                DOA_i = {Bits{1'bX}};
           end
           LastCycleAAddress = A_i;
        end
        2'b01: begin
           if (AddressRangeCheck(A_i)) begin
              if (A_i == LastCycleBAddress) begin
                 if ((Last_WEBN_i == 1'b1)&&($time-Last_tc_ClkB_PosEdge<Tr2w)) begin
                    ErrorMessage(1);
                    //DOB_i = {Bits{1'bX}};
                    #0 disable TOHDOB;
                    NODELAYB = 1'b1;
                    DOB_i = {Bits{1'bX}};
                    Memory[A_i] = DIA_i;
                 end else if ((Last_WEBN_i == 1'b0)&&($time-Last_tc_ClkB_PosEdge<Tw2r)) begin
                    ErrorMessage(4);
                    Memory[A_i] = {Bits{1'bX}};
                 end else begin
                    Memory[A_i] = DIA_i;
                 end
              end else begin
                 Memory[A_i] = DIA_i;
              end
              if (NO_SER_TOH == `TRUE) begin
                 if (A_i !== last_A) begin
                     NODELAYA = 1'b1;
                     DOA_tmp = Memory[A_i];
                     ->EventTOHDOA;
                 end else begin
                    if (DIA_i !== last_DIA) begin
                       NODELAYA = 1'b1;
                       DOA_tmp = Memory[A_i];
                       ->EventTOHDOA;
                    end else begin
                       NODELAYA = 1'b0;
                       DOA_tmp = Memory[A_i];
                       DOA_i = DOA_tmp;
                    end
                 end
              end else begin
                  NODELAYA = 1'b1;
                  DOA_tmp = Memory[A_i];
                  ->EventTOHDOA;
              end
           end else begin
                all_core_xA(9999,1);
           end
           LastCycleAAddress = A_i;
        end
        2'b1x: begin
           //DOA_i = {Bits{1'bX}};
           #0 disable TOHDOA;
           NODELAYA = 1'b1;
           DOA_i = {Bits{1'bX}};
        end
        2'b0x,
        2'bx1,
        2'bxx: begin
           if (AddressRangeCheck(A_i)) begin
                Memory[A_i] = {Bits{1'bX}};
                //DOA_i = {Bits{1'bX}};
                #0 disable TOHDOA;
                NODELAYA = 1'b1;
                DOA_i = {Bits{1'bX}};
           end else begin
                all_core_xA(9999,1);
           end
        end
      endcase
      Last_WEAN_i = WEAN_i;
  end
  endtask //memory_functionA;

  task memory_functionB;
    begin
      B_i                            = Latch_B;
      DIB_i                          = Latch_DIB;
      WEBN_i                         = Latch_WEBN;
      CSB_i                          = Latch_CSB;

      if (CSB_ == 1'b1) B_monitor;

      casez({WEBN_i,CSB_i})
        2'b11: begin
           if (AddressRangeCheck(B_i)) begin
              if ((B_i == LastCycleAAddress)&&
                  (Last_WEAN_i == 1'b0) &&
                  ($time-Last_tc_ClkA_PosEdge<Tw2r)) begin
                  ErrorMessage(1);
                  #0 disable TOHDOB;
                  NODELAYB = 1'b1;
                  DOB_i = {Bits{1'bX}};
              end else begin
                  if (NO_SER_TOH == `TRUE) begin
                    if (B_i !== last_B) begin
                       NODELAYB = 1'b1;
                       DOB_tmp = Memory[B_i];
                       ->EventTOHDOB;
                    end else begin
                       NODELAYB = 1'b0;
                       DOB_tmp  = Memory[B_i];
                       DOB_i    = DOB_tmp;
                    end
                  end else begin
                    NODELAYB = 1'b1;
                    DOB_tmp = Memory[B_i];
                    ->EventTOHDOB;
                  end
              end
           end
           else begin
                //DOB_i = {Bits{1'bX}};
                #0 disable TOHDOB;
                NODELAYB = 1'b1;
                DOB_i = {Bits{1'bX}};
           end
           LastCycleBAddress = B_i;
        end
        2'b01: begin
           if (AddressRangeCheck(B_i)) begin
              if (B_i == LastCycleAAddress) begin
                 if ((Last_WEAN_i == 1'b1)&&($time-Last_tc_ClkA_PosEdge<Tr2w)) begin
                    ErrorMessage(1);
                    #0 disable TOHDOA;
                    NODELAYA = 1'b1;
                    DOA_i = {Bits{1'bX}};
                    Memory[B_i] = DIB_i;
                 end else if ((Last_WEAN_i == 1'b0)&&($time-Last_tc_ClkA_PosEdge<Tw2r)) begin
                    ErrorMessage(4);
                    Memory[B_i] = {Bits{1'bX}};
                 end else begin
                    Memory[B_i] = DIB_i;
                 end
              end else begin
                 Memory[B_i] = DIB_i;
              end
              if (NO_SER_TOH == `TRUE) begin
                 if (B_i !== last_B) begin
                     NODELAYB = 1'b1;
                     DOB_tmp = Memory[B_i];
                     ->EventTOHDOB;
                 end else begin
                    if (DIB_i !== last_DIB) begin
                       NODELAYB = 1'b1;
                       DOB_tmp = Memory[B_i];
                       ->EventTOHDOB;
                    end else begin
                       NODELAYB = 1'b0;
                       DOB_tmp = Memory[B_i];
                       DOB_i = DOB_tmp;
                    end
                 end
              end else begin
                  NODELAYB = 1'b1;
                  DOB_tmp = Memory[B_i];
                  ->EventTOHDOB;
              end
           end else begin
                all_core_xB(9999,1);
           end
           LastCycleBAddress = B_i;
        end
        2'b1x: begin
           //DOB_i = {Bits{1'bX}};
           #0 disable TOHDOB;
           NODELAYB = 1'b1;
           DOB_i = {Bits{1'bX}};
        end
        2'b0x,
        2'bx1,
        2'bxx: begin
           if (AddressRangeCheck(B_i)) begin
                Memory[B_i] = {Bits{1'bX}};
                //DOB_i = {Bits{1'bX}};
                #0 disable TOHDOB;
                NODELAYB = 1'b1;
                DOB_i = {Bits{1'bX}};
           end else begin
                all_core_xB(9999,1);
           end
        end
      endcase
      Last_WEBN_i = WEBN_i;
  end
  endtask //memory_functionB;

  task all_core_xA;
     input byte_num;
     input do_x;

     integer byte_num;
     integer do_x;
     integer LoopCount_Address;
     begin
       if (do_x == 1) begin
          #0 disable TOHDOA;
          NODELAYA = 1'b1;
          DOA_i = {Bits{1'bX}};
       end
       LoopCount_Address=Words-1;
       while(LoopCount_Address >=0) begin
         Memory[LoopCount_Address]={Bits{1'bX}};
         LoopCount_Address=LoopCount_Address-1;
      end
    end
  endtask //end all_core_xA;

  task all_core_xB;
     input byte_num;
     input do_x;

     integer byte_num;
     integer do_x;
     integer LoopCount_Address;
     begin
       if (do_x == 1) begin
          #0 disable TOHDOB;
          NODELAYB = 1'b1;
          DOB_i = {Bits{1'bX}};
       end
       LoopCount_Address=Words-1;
       while(LoopCount_Address >=0) begin
         Memory[LoopCount_Address]={Bits{1'bX}};
         LoopCount_Address=LoopCount_Address-1;
      end
    end
  endtask //end all_core_xB;

  task A_monitor;
     begin
       if (^(A_) !== 1'bX) begin
          flag_A_x = `FALSE;
       end
       else begin
          if (flag_A_x == `FALSE) begin
              flag_A_x = `TRUE;
              ErrorMessage(2);
          end
       end
     end
  endtask //end A_monitor;

  task B_monitor;
     begin
       if (^(B_) !== 1'bX) begin
          flag_B_x = `FALSE;
       end
       else begin
          if (flag_B_x == `FALSE) begin
              flag_B_x = `TRUE;
              ErrorMessage(2);
          end
       end
     end
  endtask //end B_monitor;

  task CSA_monitor;
     begin
       if (^(CSA_) !== 1'bX) begin
          flag_CSA_x = `FALSE;
       end
       else begin
          if (flag_CSA_x == `FALSE) begin
              flag_CSA_x = `TRUE;
              ErrorMessage(3);
          end
       end
     end
  endtask //end CSA_monitor;

  task CSB_monitor;
     begin
       if (^(CSB_) !== 1'bX) begin
          flag_CSB_x = `FALSE;
       end
       else begin
          if (flag_CSB_x == `FALSE) begin
              flag_CSB_x = `TRUE;
              ErrorMessage(3);
          end
       end
     end
  endtask //end CSB_monitor;

  task ErrorMessage;
     input error_type;
     integer error_type;

     begin
       case (error_type)
         0: $display("** MEM_Error: Abnormal transition occurred (%t) in Clock of %m",$time);
         1: $display("** MEM_Warning: Read and Write the same Address, DO is unknown (%t) in clock of %m",$time);
         2: $display("** MEM_Error: Unknown value occurred (%t) in Address of %m",$time);
         3: $display("** MEM_Error: Unknown value occurred (%t) in ChipSelect of %m",$time);
         4: $display("** MEM_Error: Port A and B write the same Address, core is unknown (%t) in clock of %m",$time);
         5: $display("** MEM_Error: Clear all memory core to unknown (%t) in clock of %m",$time);
       endcase
     end
  endtask

  function AddressRangeCheck;
      input  [AddressSize-1:0] AddressItem;
      reg    UnaryResult;
      begin
        UnaryResult = ^AddressItem;
        if(UnaryResult!==1'bX) begin
           if (AddressItem >= Words) begin
              $display("** MEM_Error: Out of range occurred (%t) in Address of %m",$time);
              AddressRangeCheck = `FALSE;
           end else begin
              AddressRangeCheck = `TRUE;
           end
        end
        else begin
           AddressRangeCheck = `FALSE;
        end
      end
  endfunction //end AddressRangeCheck;

   specify
      specparam TAA  = (125:183:313);
      specparam TRC  = (184:264:433);
      specparam THPW = (61:88:144);
      specparam TLPW = (61:88:144);
      specparam TAS  = (47:70:118);
      specparam TAH  = (9:12:19);
      specparam TWS  = (25:37:60);
      specparam TWH  = (4:7:13);
      specparam TDS  = (15:24:44);
      specparam TDH  = (1:0:0);
      specparam TCSS = (51:78:132);
      specparam TCSH = (0:0:0);
      specparam TOE  = (63:91:147);
      specparam TOZ  = (41:58:93);


      $setuphold ( posedge CKA &&& con_A,         posedge A0, TAS,     TAH,     n_flag_A0      );
      $setuphold ( posedge CKA &&& con_A,         negedge A0, TAS,     TAH,     n_flag_A0      );
      $setuphold ( posedge CKA &&& con_A,         posedge A1, TAS,     TAH,     n_flag_A1      );
      $setuphold ( posedge CKA &&& con_A,         negedge A1, TAS,     TAH,     n_flag_A1      );
      $setuphold ( posedge CKA &&& con_A,         posedge A2, TAS,     TAH,     n_flag_A2      );
      $setuphold ( posedge CKA &&& con_A,         negedge A2, TAS,     TAH,     n_flag_A2      );
      $setuphold ( posedge CKA &&& con_A,         posedge A3, TAS,     TAH,     n_flag_A3      );
      $setuphold ( posedge CKA &&& con_A,         negedge A3, TAS,     TAH,     n_flag_A3      );
      $setuphold ( posedge CKA &&& con_A,         posedge A4, TAS,     TAH,     n_flag_A4      );
      $setuphold ( posedge CKA &&& con_A,         negedge A4, TAS,     TAH,     n_flag_A4      );
      $setuphold ( posedge CKA &&& con_A,         posedge A5, TAS,     TAH,     n_flag_A5      );
      $setuphold ( posedge CKA &&& con_A,         negedge A5, TAS,     TAH,     n_flag_A5      );
      $setuphold ( posedge CKA &&& con_A,         posedge A6, TAS,     TAH,     n_flag_A6      );
      $setuphold ( posedge CKA &&& con_A,         negedge A6, TAS,     TAH,     n_flag_A6      );
      $setuphold ( posedge CKA &&& con_A,         posedge A7, TAS,     TAH,     n_flag_A7      );
      $setuphold ( posedge CKA &&& con_A,         negedge A7, TAS,     TAH,     n_flag_A7      );
      $setuphold ( posedge CKA &&& con_A,         posedge A8, TAS,     TAH,     n_flag_A8      );
      $setuphold ( posedge CKA &&& con_A,         negedge A8, TAS,     TAH,     n_flag_A8      );
      $setuphold ( posedge CKA &&& con_A,         posedge A9, TAS,     TAH,     n_flag_A9      );
      $setuphold ( posedge CKA &&& con_A,         negedge A9, TAS,     TAH,     n_flag_A9      );
      $setuphold ( posedge CKA &&& con_A,         posedge A10, TAS,     TAH,     n_flag_A10     );
      $setuphold ( posedge CKA &&& con_A,         negedge A10, TAS,     TAH,     n_flag_A10     );
      $setuphold ( posedge CKB &&& con_B,         posedge B0, TAS,     TAH,     n_flag_B0      );
      $setuphold ( posedge CKB &&& con_B,         negedge B0, TAS,     TAH,     n_flag_B0      );
      $setuphold ( posedge CKB &&& con_B,         posedge B1, TAS,     TAH,     n_flag_B1      );
      $setuphold ( posedge CKB &&& con_B,         negedge B1, TAS,     TAH,     n_flag_B1      );
      $setuphold ( posedge CKB &&& con_B,         posedge B2, TAS,     TAH,     n_flag_B2      );
      $setuphold ( posedge CKB &&& con_B,         negedge B2, TAS,     TAH,     n_flag_B2      );
      $setuphold ( posedge CKB &&& con_B,         posedge B3, TAS,     TAH,     n_flag_B3      );
      $setuphold ( posedge CKB &&& con_B,         negedge B3, TAS,     TAH,     n_flag_B3      );
      $setuphold ( posedge CKB &&& con_B,         posedge B4, TAS,     TAH,     n_flag_B4      );
      $setuphold ( posedge CKB &&& con_B,         negedge B4, TAS,     TAH,     n_flag_B4      );
      $setuphold ( posedge CKB &&& con_B,         posedge B5, TAS,     TAH,     n_flag_B5      );
      $setuphold ( posedge CKB &&& con_B,         negedge B5, TAS,     TAH,     n_flag_B5      );
      $setuphold ( posedge CKB &&& con_B,         posedge B6, TAS,     TAH,     n_flag_B6      );
      $setuphold ( posedge CKB &&& con_B,         negedge B6, TAS,     TAH,     n_flag_B6      );
      $setuphold ( posedge CKB &&& con_B,         posedge B7, TAS,     TAH,     n_flag_B7      );
      $setuphold ( posedge CKB &&& con_B,         negedge B7, TAS,     TAH,     n_flag_B7      );
      $setuphold ( posedge CKB &&& con_B,         posedge B8, TAS,     TAH,     n_flag_B8      );
      $setuphold ( posedge CKB &&& con_B,         negedge B8, TAS,     TAH,     n_flag_B8      );
      $setuphold ( posedge CKB &&& con_B,         posedge B9, TAS,     TAH,     n_flag_B9      );
      $setuphold ( posedge CKB &&& con_B,         negedge B9, TAS,     TAH,     n_flag_B9      );
      $setuphold ( posedge CKB &&& con_B,         posedge B10, TAS,     TAH,     n_flag_B10     );
      $setuphold ( posedge CKB &&& con_B,         negedge B10, TAS,     TAH,     n_flag_B10     );

      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA0, TDS,     TDH,     n_flag_DIA0    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA0, TDS,     TDH,     n_flag_DIA0    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB0, TDS,     TDH,     n_flag_DIB0    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB0, TDS,     TDH,     n_flag_DIB0    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA1, TDS,     TDH,     n_flag_DIA1    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA1, TDS,     TDH,     n_flag_DIA1    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB1, TDS,     TDH,     n_flag_DIB1    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB1, TDS,     TDH,     n_flag_DIB1    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA2, TDS,     TDH,     n_flag_DIA2    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA2, TDS,     TDH,     n_flag_DIA2    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB2, TDS,     TDH,     n_flag_DIB2    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB2, TDS,     TDH,     n_flag_DIB2    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA3, TDS,     TDH,     n_flag_DIA3    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA3, TDS,     TDH,     n_flag_DIA3    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB3, TDS,     TDH,     n_flag_DIB3    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB3, TDS,     TDH,     n_flag_DIB3    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA4, TDS,     TDH,     n_flag_DIA4    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA4, TDS,     TDH,     n_flag_DIA4    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB4, TDS,     TDH,     n_flag_DIB4    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB4, TDS,     TDH,     n_flag_DIB4    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA5, TDS,     TDH,     n_flag_DIA5    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA5, TDS,     TDH,     n_flag_DIA5    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB5, TDS,     TDH,     n_flag_DIB5    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB5, TDS,     TDH,     n_flag_DIB5    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA6, TDS,     TDH,     n_flag_DIA6    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA6, TDS,     TDH,     n_flag_DIA6    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB6, TDS,     TDH,     n_flag_DIB6    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB6, TDS,     TDH,     n_flag_DIB6    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA7, TDS,     TDH,     n_flag_DIA7    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA7, TDS,     TDH,     n_flag_DIA7    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB7, TDS,     TDH,     n_flag_DIB7    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB7, TDS,     TDH,     n_flag_DIB7    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA8, TDS,     TDH,     n_flag_DIA8    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA8, TDS,     TDH,     n_flag_DIA8    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB8, TDS,     TDH,     n_flag_DIB8    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB8, TDS,     TDH,     n_flag_DIB8    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA9, TDS,     TDH,     n_flag_DIA9    );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA9, TDS,     TDH,     n_flag_DIA9    );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB9, TDS,     TDH,     n_flag_DIB9    );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB9, TDS,     TDH,     n_flag_DIB9    );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA10, TDS,     TDH,     n_flag_DIA10   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA10, TDS,     TDH,     n_flag_DIA10   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB10, TDS,     TDH,     n_flag_DIB10   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB10, TDS,     TDH,     n_flag_DIB10   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA11, TDS,     TDH,     n_flag_DIA11   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA11, TDS,     TDH,     n_flag_DIA11   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB11, TDS,     TDH,     n_flag_DIB11   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB11, TDS,     TDH,     n_flag_DIB11   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA12, TDS,     TDH,     n_flag_DIA12   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA12, TDS,     TDH,     n_flag_DIA12   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB12, TDS,     TDH,     n_flag_DIB12   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB12, TDS,     TDH,     n_flag_DIB12   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA13, TDS,     TDH,     n_flag_DIA13   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA13, TDS,     TDH,     n_flag_DIA13   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB13, TDS,     TDH,     n_flag_DIB13   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB13, TDS,     TDH,     n_flag_DIB13   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA14, TDS,     TDH,     n_flag_DIA14   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA14, TDS,     TDH,     n_flag_DIA14   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB14, TDS,     TDH,     n_flag_DIB14   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB14, TDS,     TDH,     n_flag_DIB14   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA15, TDS,     TDH,     n_flag_DIA15   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA15, TDS,     TDH,     n_flag_DIA15   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB15, TDS,     TDH,     n_flag_DIB15   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB15, TDS,     TDH,     n_flag_DIB15   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA16, TDS,     TDH,     n_flag_DIA16   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA16, TDS,     TDH,     n_flag_DIA16   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB16, TDS,     TDH,     n_flag_DIB16   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB16, TDS,     TDH,     n_flag_DIB16   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA17, TDS,     TDH,     n_flag_DIA17   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA17, TDS,     TDH,     n_flag_DIA17   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB17, TDS,     TDH,     n_flag_DIB17   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB17, TDS,     TDH,     n_flag_DIB17   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA18, TDS,     TDH,     n_flag_DIA18   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA18, TDS,     TDH,     n_flag_DIA18   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB18, TDS,     TDH,     n_flag_DIB18   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB18, TDS,     TDH,     n_flag_DIB18   );
      $setuphold ( posedge CKA &&& con_DIA,       posedge DIA19, TDS,     TDH,     n_flag_DIA19   );
      $setuphold ( posedge CKA &&& con_DIA,       negedge DIA19, TDS,     TDH,     n_flag_DIA19   );
      $setuphold ( posedge CKB &&& con_DIB,       posedge DIB19, TDS,     TDH,     n_flag_DIB19   );
      $setuphold ( posedge CKB &&& con_DIB,       negedge DIB19, TDS,     TDH,     n_flag_DIB19   );

      $setuphold ( posedge CKA &&& con_WEAN,      posedge WEAN, TWS,     TWH,     n_flag_WEAN    );
      $setuphold ( posedge CKA &&& con_WEAN,      negedge WEAN, TWS,     TWH,     n_flag_WEAN    );
      $setuphold ( posedge CKB &&& con_WEBN,      posedge WEBN, TWS,     TWH,     n_flag_WEBN    );
      $setuphold ( posedge CKB &&& con_WEBN,      negedge WEBN, TWS,     TWH,     n_flag_WEBN    );
      $setuphold ( posedge CKA,                   posedge CSA, TCSS,    TCSH,    n_flag_CSA     );
      $setuphold ( posedge CKA,                   negedge CSA, TCSS,    TCSH,    n_flag_CSA     );
      $setuphold ( posedge CKB,                   posedge CSB, TCSS,    TCSH,    n_flag_CSB     );
      $setuphold ( posedge CKB,                   negedge CSB, TCSS,    TCSH,    n_flag_CSB     );
      $period    ( posedge CKA &&& con_CKA,       TRC,                       n_flag_CKA_PER );
      $width     ( posedge CKA &&& con_CKA,       THPW,    0,                n_flag_CKA_MINH);
      $width     ( negedge CKA &&& con_CKA,       TLPW,    0,                n_flag_CKA_MINL);
      $period    ( posedge CKB &&& con_CKB,       TRC,                       n_flag_CKB_PER );
      $width     ( posedge CKB &&& con_CKB,       THPW,    0,                n_flag_CKB_MINH);
      $width     ( negedge CKB &&& con_CKB,       TLPW,    0,                n_flag_CKB_MINL);

      if (NODELAYA == 0)  (posedge CKA => (DOA0 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB0 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA1 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB1 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA2 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB2 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA3 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB3 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA4 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB4 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA5 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB5 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA6 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB6 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA7 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB7 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA8 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB8 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA9 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB9 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA10 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB10 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA11 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB11 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA12 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB12 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA13 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB13 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA14 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB14 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA15 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB15 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA16 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB16 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA17 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB17 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA18 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB18 :1'bx)) = TAA  ;
      if (NODELAYA == 0)  (posedge CKA => (DOA19 :1'bx)) = TAA  ;
      if (NODELAYB == 0)  (posedge CKB => (DOB19 :1'bx)) = TAA  ;


      (OEA => DOA0) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB0) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA1) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB1) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA2) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB2) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA3) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB3) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA4) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB4) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA5) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB5) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA6) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB6) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA7) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB7) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA8) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB8) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA9) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB9) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA10) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB10) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA11) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB11) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA12) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB12) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA13) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB13) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA14) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB14) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA15) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB15) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA16) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB16) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA17) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB17) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA18) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB18) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEA => DOA19) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
      (OEB => DOB19) = (TOE,  TOE,  TOZ,  TOE,  TOZ,  TOE  );
   endspecify

`endprotect
endmodule
