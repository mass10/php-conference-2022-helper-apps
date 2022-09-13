#!/usr/bin/env perl
# coding: utf-8

use lib '/home/irisa/perl5/lib/perl5';

use strict;
use utf8;
use LWP::UserAgent;
use Data::Dumper;
use WWW::Mechanize;

sub _between {

	my ($source, $begin, $end) = @_;

	if (length($begin)) {
		# 開始マーカーが指定されている
		my $pos = index($source, $begin);
		if ($pos == -1) {
			# みつからない
			return '';
		}
		$source = substr($source, $pos + length($begin));
	}

	if (length($end)) {
		# 終了マーカーが指定されている
		my $pos = index($source, $end);
		if ($pos == -1) {
			# みつからない
			return '';
		}
		$source = substr($source, 0, $pos);
	}

	return $source;
}

# ファイル作成
sub _create_text_file {
	my ($path, $content) = @_;

	my $stream = undef;
	open($stream, '>'.$path);
	binmode($stream, ':utf8');
	print($stream $content);
	close($stream);
}

# スポンサーページをダウンロードする
sub _query_sponsors {

	my $session = WWW::Mechanize->new();
	$session->get('https://fortee.jp/login');

	# ========== ログインを試みる ==========
	my $form = {};
	$form->{username} = 'irisawamasaru';
	$form->{password} = 'Hello,fortee!!!!';
	my $result = $session->submit_form(
		fields => $form
	);

	# print("--- SUBMIT RESULT ---\n");
	# print(Data::Dumper::Dumper($result), "\n");

	# ========== スポンサーページへ移動 ==========

	# ERROR: Link not found.
	# $session->follow_link(url => 'https://fortee.jp/phpcon-2022/organizer/sponsor/index-by-plans');

	$session->get('https://fortee.jp/phpcon-2022/organizer/sponsor/index-by-plans');
	my $content = $session->content();
	return $content;
}

# コンテンツを解析します。
sub _diagnose_sponsors {

	my ($path) = @_;

	my $stream = undef;
	if (!open($stream, $path)) {
		die $!;
	}
	binmode($stream, ':utf8');

	# my $sponsors_map = {};
	while (my $line = <$stream>) {
		if ($line =~ m/\<a\ href\=\"\/phpcon-2022\/organizer\/sponsor\/view\//ms) {
			$line = _between($line, '', '/a>');
			my $line = _between($line, '<a href="/phpcon-2022/organizer/sponsor/view/', '');
			my $sponsor_id = _between($line, '', '"');
			if (!length($sponsor_id)) {
				next;
			}
			my $sponsor_name = _between($line, '>', '<');
			print($sponsor_id, "\t", $sponsor_name);
		}
		elsif ($line =~ m/<span class="badge badge-secondary">/ms) {
			my $plan_name = _between($line, '<span class="badge badge-secondary">', '</span');
			print("\t", $plan_name, "\n");
		}
	}

	close($stream);
}

sub _download_sponsor_page_as {

	my ($path) = @_;

	# スポンサーページをダウンロードしています。
	my $content = _query_sponsors();
	if (!length($content)) {
		die;
	}
	_create_text_file($path, $content);

	return $path;
}

sub _main {

	binmode(STDIN,  ':utf8');
	binmode(STDOUT, ':utf8');
	binmode(STDERR, ':utf8');


	# ====================
	# DOWNLOAD SPONSOR PAGE
	# ====================
	# スポンサーページをダウンロードしています。
	my $path = 'result.html';
	_download_sponsor_page_as($path);

	# ====================
	# DIAGNOSE
	# ====================
	_diagnose_sponsors($path);
}

_main();
