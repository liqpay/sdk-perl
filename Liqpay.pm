package Liqpay;
use strict;
use HTTP::Request;
use Digest::SHA1 qw/sha1_base64 sha1/;
use MIME::Base64 qw/encode_base64 decode_base64/;
use JSON;
use LWP::UserAgent;

sub new
{
    my ($class, $public_key,$private_key) = @_;
    my $self = {};
    bless $self, $class;
    $self->{public_key} = $public_key;
    $self->{private_key} = $private_key;
    return $self;
}



sub cnb_form
{
	my ($self,$payment,$button_conf) = @_;
	my $ch_pars;
	$ch_pars = $self->check_params($payment);
	if ($ch_pars == 0)
	{
		return 'wrong_params';	
	}
	$payment = $ch_pars;
	
	
	$payment->{language} = 'ru' if !exists $payment->{language};
	$payment->{language} = 'en' if $payment->{language} eq 'en';

	my $data = encode_base64(encode_json($payment),'');
    my $signature = encode_base64(sha1($self->{private_key}.$data.$self->{private_key}),'');

	my $form = qq[<form id='liqpay_form' method="post" action="https://www.liqpay.com/api/3/checkout" accept-charset="utf-8"> \n];
	
	   $form .= qq[<input type="hidden" name="data" value="].$data.qq[" />\n];
	   $form .= qq[<input type="hidden" name="signature" value="].$signature.qq[" />\n];

	if ($button_conf eq '')
	{
		$form .= qq[<input type="image" src="//static.liqpay.com/buttons/p1].$payment->{language}.qq[.radius.png" name="btn_text" />];	
	}
	elsif($button_conf ne '' && $button_conf ne 'none')
	{
		$form .= $button_conf;
	}
	$form .= qq[</form>];
    return $form;
}

sub api
{
	my ($self,$req_url,$payment) = @_;
	my $url = "https://www.liqpay.com/api/".$req_url;
	$payment->{public_key} = $self->{public_key};
	my $data = encode_base64(encode_json($payment),'');
    my $signature = encode_base64(sha1($self->{private_key}.$data.$self->{private_key}),'');
	chop $data;
    chop $signature;
	$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
	my $ua = LWP::UserAgent->new(timeout=>60,verify_hostname => 0);
	my $req = HTTP::Request->new('POST',$url);
	$req->header("Content-Type"=>"application/json");
	my $content = "data=$data&signature=$signature";
	$req->content($content);
	my $resp = $ua->request($req);
	return decode_json($resp->content);
}


sub cnb_signature
{
	my ($self,$payment) = @_;
	my $signature;
	$payment->{public_key} = $self->{public_key};
	my $data = encode_base64(encode_json($payment),'');	
    $signature = encode_base64(sha1($self->{private_key}.$data.$self->{private_key}),'');
	return $signature;
}


sub str_to_sign
{        
	my ($self,$str) = @_;
    my $signature = encode_base64(sha1($str),'');
    chop($signature);
    return $signature;
}

sub check_params
{
	my ($self,$payment) = @_;
	$payment->{currency} = 'RUB' if $payment->{currency} eq 'RUR';
	return $payment;
}

1;