#!/usr/bin/perl -w
use strict;
use utf8;

use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Encode;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple;
use Email::Simple::Creator;


my $modem      = '192.168.99.1';
my $emailInfo  = 'info@example.com';
my $sms_list   = "http://$modem/goform/goform_get_cmd_process?isTest=false&cmd=sms_data_total&page=0&data_per_page=500&mem_store=1&tags=10&order_by=order+by+id+desc";
my $sms_delete = "http://$modem/goform/goform_set_cmd_process";

my $ua = LWP::UserAgent->new;
my $req_list = HTTP::Request->new(GET => $sms_list);
my $resp = $ua->request($req_list);

my $body = $resp->decoded_content;
my $messages = decode_json $body;
my $sms = $messages->{messages}->[0];
my $content = $sms->{content};
my $content_decoded = decode('UCS-2', pack 'H*', $content);
$sms->{content_decoded} = $content_decoded;

my $email = Email::Simple->create(
    header => [
        To      => $emailInfo,
        From    => $emailInfo,
        Subject => "[SMS] $sms->{number}",
    ],
    body => "Text: $sms->{content_decoded}\n",
);
my $transport = Email::Sender::Transport::SMTP::TLS->new(
    host => 'smtp.gmail.com',
    port => 587,
    username => $emailInfo,
    password => 'password',
    helo => 'somehost,
);
sendmail($email, { transport => $transport });

$resp = $ua->post(
    $sms_delete,
    {
        isTest      => 'false',
        goformId    => 'DELETE_SMS',
        msg_id      => "$sms->{id};",
        notCallback => 'true',
    }
);

#die Dumper($email, $sms);
