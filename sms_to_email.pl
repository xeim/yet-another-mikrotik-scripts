#!/usr/bin/perl -w
# Get one oldest SMS from ZTE MF825A (MTS 830FT) modem by HTTP
# Send SMS to email and delete SMS from modem

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
use Storable;

my $modem      = '192.168.99.1';
my $phone      = '+7916NNNNNNN';
my $emailInfo  = 'info@example.com';
my $timeZone   = 'UTC';
my $sms_list   = "http://$modem/goform/goform_get_cmd_process?isTest=false&cmd=sms_data_total&page=0&data_per_page=500&mem_store=1&tags=10&order_by=order+by+id+desc";
my $sms_delete = "http://$modem/goform/goform_set_cmd_process";
my $tmpfile    = '/tmp/sms_sZFNfR2eOH';
my $bot        = 'botNNNNNNNNN:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
my $telegram   = "https://api.telegram.org/$bot/sendMessage";
my $chat       = 'NNNNNNNNN';

my $ua = LWP::UserAgent->new;
my $req_list = HTTP::Request->new(GET => $sms_list);
my $resp = $ua->request($req_list);
exit if $resp->code != 200;
my $body = $resp->decoded_content;
my $json = decode_json $body;
exit if !scalar @{ $json->{messages} };
my $sms = $json->{messages}->[-1];

my $stor = eval { retrieve $tmpfile };
if (!$sms->{received_all_concat_sms} && ++$stor->{count} <= 3) {
    store $stor, $tmpfile;

    openlog('sms_to_email.pl', 'pid');
    syslog('info', 'Partial SMS in modem %s from %s found. Waiting %s', $modem, $sms->{number}, $stor->{count});
    closelog();

    exit;
} else {
    unlink $tmpfile;
}

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

$ua->post(
    $telegram, {
        chat_id    => $chat,
        parse_mode => 'markdown',
        text       => 'New message from *' . $sms->{number} . '*',
    }
);

my $email = MIME::Entity->build(
    Type     => 'text/plain',
    Encoding => 'quoted-printable',
    Charset  => 'UTF-8',
    Date     => DateTime::Format::Mail->format_datetime( $sms->{datetime} ),
    To       => encode('MIME-Header', $phone        ) . " <$emailInfo>",
    From     => encode('MIME-Header', $sms->{number}) . " <$emailInfo>",
    Subject  => encode('MIME-Header', '[SMS]'),
    Data     => $sms->{text},
);
sendmail($email);

$resp = $ua->post(
    $sms_delete, {
        isTest      => 'false',
        goformId    => 'DELETE_SMS',
        msg_id      => "$sms->{id};",
        notCallback => 'true',
    }
);

#die Dumper($email, $sms);
