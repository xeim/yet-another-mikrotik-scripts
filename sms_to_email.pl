#!/usr/bin/perl -w
use strict;
use utf8;
binmode(STDOUT,':utf8');

use Data::Dumper;
use Encode;
use Sys::Syslog;
use DateTime;
use DateTime::Format::Mail;
use LWP::UserAgent;
use JSON;
use MIME::Entity;
use Email::Sender::Simple qw(sendmail);

my $modem      = '192.168.99.1';
my $phone      = '+7916NNNNNNN';
my $emailInfo  = 'info@example.com';
my $timeZone   = 'UTC';
my $sms_list   = "http://$modem/goform/goform_get_cmd_process?isTest=false&cmd=sms_data_total&page=0&data_per_page=500&mem_store=1&tags=10&order_by=order+by+id+desc";
my $sms_delete = "http://$modem/goform/goform_set_cmd_process";

my $ua = LWP::UserAgent->new;
my $req_list = HTTP::Request->new(GET => $sms_list);
my $resp = $ua->request($req_list);
my $body = $resp->decoded_content;
my $json = decode_json $body;
exit if !scalar @{ $json->{messages} };

my $sms = $json->{messages}->[-1];
exit if !$sms->{received_all_concat_sms};
$sms->{text} = encode('UTF-8', decode('UCS-2', pack 'H*', $sms->{content}) );
my ($year, $month, $day, $hour, $minute, $second) = split ',', $sms->{'date'};
$sms->{datetime} = DateTime->new(
    year      => 2000 + $year,
    month     => $month,
    day       => $day,
    hour      => $hour,
    minute    => $minute,
    second    => $second,
    time_zone => $timeZone,
);

openlog('sms_to_email.pl', 'pid');
syslog('info', 'New SMS in modem %s from %s found', $modem, $sms->{number});
closelog();

my $email = MIME::Entity->build(
    Type     => 'text/plain',
    Encoding => 'quoted-printable',
    Charset  => 'UTF-8',
    Date     => DateTime::Format::Mail->format_datetime( $sms->{datetime} ),
    To       => encode('MIME-Header', $phone        ) . " <$emailInfo>",
    From     => encode('MIME-Header', $sms->{number}) . " <$emailInfo>",
    Subject  => encode('MIME-Header', '[SMS]'),
    Data     => $sms->{text}
);
sendmail($email);

$resp = $ua->post(
    $sms_delete,
    {
        isTest      => 'false',
        goformId    => 'DELETE_SMS',
        msg_id      => "$sms->{id};",
        notCallback => 'true'
    }
);
