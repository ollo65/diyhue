################################################################################
# 10_BREMATIC_LAN
# $Id: $
#
################################################################################
#
#  Copyright notice
#
#  (c) 2014 Copyright: Thomas Proepper
#
#  This file is part of fhem.
# 
#  Fhem is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
# 
#  Fhem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with fhem.  If not, see <http://www.gnu.org/licenses/>.
#
#  Disclaimer: The Author takes no responsibility whatsoever 
#  for damages potentially done by this program.
#
################################################################################

package main;
use strict;
use warnings;

my %IT_1st = (
  "A","1111","B","0111","C","1011","D","0011","E","1101","F","0101",
  "G","1001","H","0001","I","1110","J","0110","K","1010","L","0010",
  "M","1100","N","0100","O","1000","P","0000"
  );
my %IT_2nd = (
  "1" ,"1111","2" ,"0111","3" ,"1011","4" ,"0011","5" ,"1101","6" ,"0101",
  "7" ,"1001","8" ,"0001","9" ,"1110","10","0110","11","1010","12","0010",
  "13","1100","14","0100","15","1000","16","0000"
  );

	
sub BREMATIC_LAN_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}      = 'BRL_Define';
    $hash->{WriteFn}    = 'BRL_Write';
}

sub BRL_Define($$) {
  my ($hash, $def) = @_;
  my @param = split('[ \t]+', $def);
    
  if(int(@param) < 3) {
    return "Usage: define <name> BREMATIC_LAN <IP-adress> [<port>]";
  }
    
  $hash->{IP}    = $param[2];

  if(!$param[3]) {
    $hash->{PORT}  = "49880";  
  } else {
    $hash->{PORT}  = $param[3];
  }

  $hash->{INTERVAL} = 60;
  #InternalTimer(gettimeofday()+2, "BRL_GetUpdate", $hash, 0);
  $hash->{STATE}     = "Initialized";

  return undef;
}

#####################################
# Check if device present
sub BRL_GetUpdate($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
	
  Log3 "1", 1, "IP: ".$hash->{IP};
  Log3 "1", 1, "Interval: ".$hash->{INTERVAL};

  if(PingState($hash->{IP}) eq "ok") {
    $hash->{STATE}     = "alive";
  } else {
    $hash->{STATE}     = "absent";
  }
	
  #InternalTimer(gettimeofday()+$hash->{INTERVAL}, "BRL_GetUpdate", $hash, 1);

  return undef;
}
	
#####################################
# Goto specific send function
sub BRL_Write($$$$$) {
  my ($hash, $coding, $master, $slave, $action)=@_;
	
  my $name     = $hash->{NAME};
  my $dev      = $hash->{IP}.":".$hash->{PORT};
  my $SendData = "";

  #return "Device not alive" if($hash->{STATE} ne "alive");
  
  if($coding eq "B2") {
    $SendData = BRL_type_B2 ($hash, $master, $slave, $action);
  }
  if($coding eq "IT") {
    $SendData = BRL_type_IT ($hash, $master, $slave, $action);
  }

	if($SendData ne "") {
		my ($socket,$data);
   
		#  We call IO::Socket::INET->new() to create the UDP Socket
		Log3 $name, 1, "BRL_Write: $SendData";
		$socket = new IO::Socket::INET(PeerAddr=>$dev,Proto=>'udp') or die "ERROR in Socket Creation : $!\n";
		$socket->send($SendData);

		$socket->close();	
	}
  
  return undef;
}

#####################################
# Send commands to BREMATIC
sub BRL_type_B2($$$$) {
  my ($hash, $master, $slave, $action)=@_;
  
  my $name      = $hash->{NAME};
  my $SendData  = "";
 
  my $A         = "0";
  my $G         = "0";
  my $Repeat    = "10";
  my $Pause     = "5600";
  my $Tune      = "350";
  my $Baud      = "25";
  my $HEAD      = "TXP:$A,$G,$Repeat,$Pause,$Tune,$Baud,";

  my $txversion = "2";
  my $Speed     = "16";
  my $TAIL      = ",$txversion,1,$Speed,;";

  my $bitLow    = "1";
  my $bitHgh    = "3";
  my $seqLow    = "3,3,1,1,";
  my $seqHgh    = "3,1,3,1,";
  
  my $AN        = "1,3,1,3,3";
  my $AUS       = "3,1,1,3,1";

  my $msgM = CalcCode($master, $seqLow, $seqHgh);
  my $msgS = CalcCode($slave, $seqLow, $seqHgh);

  if ( $action eq "on" ) {
    $SendData = $HEAD.$bitLow.",".$msgM.$msgS.$bitHgh.",".$AN.$TAIL;
  } else {
    $SendData = $HEAD.$bitLow.",".$msgM.$msgS.$bitHgh.",".$AUS.$TAIL;
  }

  return $SendData;
 }


#####################################
# Send commands to INTERTECHNO
sub BRL_type_IT($$$$) {
  my ($hash, $master, $slave, $action)=@_;
  
  my $name      = $hash->{NAME};
  my $SendData  = "";

  my $sA         = "0";
  my $sG         = "0";
  my $sRepeat    = "12";
  my $sPause     = "11125";
  my $sTune      = "89";
  my $sBaud      = "25";
  my $HEAD      = "TXP:$sA,$sG,$sRepeat,$sPause,$sTune,$sBaud,";
  Log3 $name, 1, "HEAD: $HEAD";

  my $sSpeed     = "4";

  my $TAIL      = ",1,$sSpeed,;";
  Log3 $name, 1, "TAIL: $TAIL";
  
  my $bitLow    = "4";
  my $bitHgh    = "12";
  my $seqLow    = "12,12,4,4,";
  my $seqHgh    = "12,4,12,4,";

  my $AN        = "12,4,4,12,12,4";
  my $AUS       = "12,4,4,12,4,12";

  # calculate transmit code from IT A-P rotary switches
  my $msgM = CalcCode($IT_1st{$master}, $seqLow, $seqHgh);
  Log3 $name, 1, "Master: $master => $msgM";
  my $msgS = CalcCode($IT_2nd{$slave}, $seqLow, $seqHgh);
  Log3 $name, 1, "Slave:  $slave => $msgS";
  my $msgE = CalcCode("10", $seqLow, $seqHgh);

  $SendData = $HEAD.$bitLow.",".$msgM.$msgS.$msgE.$bitHgh.",";
  
  if ( $action eq "on" ) {
    $SendData = $SendData.$AN;
    Log3 $name, 1, "AN: $AN";
  } else {
    $SendData = $SendData.$AUS;
    Log3 $name, 1, "AUS: $AUS";
  }
  $SendData = $SendData.$TAIL;

  #my $hexdata = "09130000400405015E00";
	#my $bindata = unpack("B*", pack("H*", $hexdata));
	#Log3 $name, 1, "hexdata: $hexdata";
	#Log3 $name, 1, "bindata: $bindata";
	#$SendData = CalcCode($bindata, $Bit0, $Bit1);
	#Log3 $name, 1, "msg: $SendData";
	
  return $SendData;  
}
 
#####################################
# Calculate Code
sub CalcCode($$$){
  my ($code, $seqLow, $seqHgh) = @_;

  my $i = 0;
  my $bit = "";
  my $msg = "";

  for ( $i=0; $i<length($code); $i++ ) {   
    $bit = substr($code, $i, 1);
    if ( $bit == "0" ) {
      $msg = $msg.$seqLow;
    } else {
      $msg = $msg.$seqHgh;
    }
  }
	
  return $msg;
}

1;

=pod
=begin html

<a name="BREMATIC_LAN"></a>
<h3>BREMATIC_LAN</h3>
<ul>
    <i>BREMATIC_LAN</i> implements the Brematic GWY 433 
    in-depth instruction to your first module.
    <br><br>
    <a name="Hellodefine"></a>
    <b>Define</b>
    <ul>
        <code>define <name> BREMATIC_LAN <ip-adress> [<port>]</code>
        <br><br>
        Example: <code>define HELLO Hello TurnUrRadioOn</code>
        <br><br>
        The "greet" parameter has no further meaning, it just demonstrates
        how to set a so called "Internal" value. See <a href="http://fhem.de/commandref.html#define">commandref#define</a> 
        for more info about the define command.
    </ul>
    <br>
    
    <a name="Helloset"></a>
    <b>Set</b><br>
    <ul>
        <code>set <name> <option> <value></code>
        <br><br>
        You can <i>set</i> any value to any of the following options. They're just there to 
        <i>get</i> them. See <a href="http://fhem.de/commandref.html#set">commandref#set</a> 
        for more info about the set command.
        <br><br>
        Options:
        <ul>
              <li><i>satisfaction</i><br>
                  Defaults to "no"</li>
              <li><i>whatyouwant</i><br>
                  Defaults to "can't"</li>
              <li><i>whatyouneed</i><br>
                  Defaults to "try sometimes"</li>
        </ul>
    </ul>
    <br>

    <a name="Helloget"></a>
    <b>Get</b><br>
    <ul>
        <code>get <name> <option></code>
        <br><br>
        You can <i>get</i> the value of any of the options described in 
        <a href="#Helloset">paragraph "Set" above</a>. See 
        <a href="http://fhem.de/commandref.html#get">commandref#get</a> for more info about 
        the get command.
    </ul>
    <br>
    
    <a name="Helloattr"></a>
    <b>Attributes</b>
    <ul>
        <code>attr <name> <attribute> <value></code>
        <br><br>
        See <a href="http://fhem.de/commandref.html#attr">commandref#attr</a> for more info about 
        the attr command.
        <br><br>
        Attributes:
        <ul>
            <li><i>formal</i> no|yes<br>
                When you set formal to "yes", all output of <i>get</i> will be in a
                more formal language. Default is "no".
            </li>
        </ul>
    </ul>
</ul>

=end html

=cut
