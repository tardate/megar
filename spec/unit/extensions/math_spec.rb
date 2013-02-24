require 'spec_helper'

describe "Math.powm" do

  subject { Math.powm(b, p, m) }

  context "when small numbers" do
    let(:b) { 3 }
    let(:p) { 2 }
    let(:m) { 2 }
    it { should eql(1) }
  end

  context "when mega numbers" do
    let(:b) { 12983373611079770211598532059277454574873142790933720755590694119490820724884320773416062882872824441407372114886530726474979688565347545388995368928786174580865050206056588702714047747117203947610116835797727211967502240199908615095083794940126702458539176340055473274185983336006544169353743065050853660077890672872837121852471639967733140753846470653509594838648433786451039871566965471109413962221372977032372323023277197880477708795783672178465649341215154594913545491105371339761229791332444362145738176132020340880433834911670388940905488618362858862479443215147800580019791462743546344709458220309095035153113 }
    let(:p) { 145152480967442902710798365717824992407539346469007950427947366246418381110497813913858957184058405066632963688414200899762074556635208659933679812460151505046070928204691401275085086735464744077411206367875411771694473049724208018450885347494899144266437372521383994850220996849268745979417013187349849634843 }
    let(:m) { 142281187671710416869275196755125318539473540637032484403888464391289938418112669687981856743914459731863778035997945316748255907504882215849378865708087640335269803246793543314284773670481750851308061490898252628799994463123391676396043625029999665330718877331066039172562710647546041034169018526295459116796 }
    it { should eql(129028932005782897949279696471325767689863886085968295661273887017485942014684847994821939446802702313479280634487930434066911827155895340444010316539793570826688827771870190726606362290595576791790500802375897358738534808944235383146154267477154590358447966848765704651511264321191969959365555458361318699345) }
  end

end