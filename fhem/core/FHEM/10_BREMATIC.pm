################################################################################
# 10_BREMATIC
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

my @BRE_types = (
	"switch",
	"roller",
	);

my @BRE_coding = (
	"B2",
	"IT",
	);

my %BRE_setS = (
	"toggle" => "toggle:noArg",
	"off"    => "off:noArg",
	"on"     => "on:noArg",
	);
	
sub BREMATIC_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}      = 'BRE_Define';
    $hash->{SetFn}      = 'BRE_Set';
	$hash->{AttrList}   = "IODev";
}

sub BRE_Define($$) {
  my ($hash, $def) = @_;
  my @param = split('[ \t]+', $def);
    
  if(int(@param) < 5){
    return "Usage: define <name> BREMATIC <BREMATIC_LAN> <master> <slave> [<type> <coding>]";
  }

  my $name         = $param[0];
  my $iodev        = $param[2]; #Prüfen
  $hash->{master}  = $param[3];
  $hash->{slave}   = $param[4];
  
  if ( $param[5] ~~ @BRE_types ){
      Log3 $name, 1, "$name: true param5 is " . $param[5];
      $hash->{type}  = $param[5];
    } else {
       $hash->{type} = "switch";
    }
  
  if ( $param[6] ~~ @BRE_coding ){
    $hash->{coding}  = $param[6];
  } else {
     $hash->{coding} = "B2";
  } 
  $hash->{STATE}     = "Initialized";
  
  AssignIoPort($hash,$iodev) if( !$hash->{IODev} );
  if( defined($hash->{IODev}->{NAME}) ){
    Log3 $name, 4, "$name: I/O device is " . $hash->{IODev}->{NAME};
  } else {
  my $ret = "$name: no I/O device";
  Log3 $name, 1, $ret;
  }
 
  Log3 $name, 1, "type: " .$hash->{type};
 
  if( $hash->{type} eq "roller" ){
   $attr{$name}{eventMap};
   my $cmdret=CommandAttr(undef,"$name eventMap on:down off:up") if (!AttrVal($name,'eventMap',undef));
  }

  return undef;
}

sub BRE_Set($@) {
  my ($hash, @param) = @_;

  return "\"set Brematic\" needs at least one argument" if (int(@param) < 2);

  my $name = shift @param;
  my $value = join("", @param);

  return "Unknown argument $value, choose one of " . join(" ", values %BRE_setS) if(!defined($BRE_setS{$value}));

  my $state = $hash->{STATE};
  if($value eq "toggle") {
    $value = "on" if($state eq "off");
    $value = "off" if($state eq "on");
  }
  $hash->{STATE} = $value;

  my $master = $hash->{master};
  my $slave  = $hash->{slave};
  my $coding = $hash->{coding};

  IOWrite($hash, $coding, $master, $slave, $value);
  #return "$opt set to $value. Try to get it.";
  return undef;
}

1;

=pod
=begin html

<a name="brematic"></a>
<h3>brematic</h3>
<ul>
    <i>BREMATIC</i> implements the classical "Hello World" as a starting point for module development. 
    You may want to copy 98_Hello.pm to start implementing a module of your very own. See 
    <a href="http://www.fhemwiki.de/wiki/DevelopmentModuleIntro">DevelopmentModuleIntro</a> for an 
    in-depth instruction to your first module.
    <br><br>
    <a name="brematicdefine"></a>
    <b>Define</b>
    <ul>
        <code>define <name> brematic <greet></code>
        <br><br>
        Example: <code>define HELLO Hello TurnUrRadioOn</code>
        <br><br>
        The "greet" parameter has no further meaning, it just demonstrates
        how to set a so called "Internal" value. See <a href="http://fhem.de/commandref.html#define">commandref#define</a> 
        for more info about the define command.
    </ul>
    <br>
    
    <a name="brematicset"></a>
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
