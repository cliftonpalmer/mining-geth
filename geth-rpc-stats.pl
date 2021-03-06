#!/usr/bin/perl
use strict;
#use warnings;
use v5.10;

use HTTP::Tiny;
use JSON;
use Data::Dumper;

my $http = HTTP::Tiny->new(
	default_headers => { 'content-type' => 'application/json' }
);

my $json = JSON->new->allow_nonref;

sub geth_rpc {
	my $data = {
		jsonrpc => '2.0',
		method  => shift,
		params  => shift,
		id      => $$,
	};
	my $response = $http->request('POST', 'http://localhost:8545', { content => to_json($data) });
	if ($response->{success}) {
		my $content = from_json($response->{content});
		if ($content->{error}) {
			warn Dumper($content);
			return undef
		}
		else {
			return $content->{result};
		}
	}
	else {
		warn Dumper($response);
		die "No success with geth RPC\n";
	}
}

say 'BlockNumber: ' . hex geth_rpc('eth_blockNumber', []);
say 'PeerCount: ' . hex geth_rpc('net_peerCount', []);

# syncing data
my $syncing = geth_rpc('eth_syncing', []);
say 'Syncing: ' . $json->pretty->encode($syncing);
if ($syncing) {
	my $currentBlock = hex $syncing->{currentBlock};
	say "Current block: $currentBlock";
	my $highestBlock = hex $syncing->{highestBlock};
	say "Highest block: $highestBlock";
	printf "Sync delta: %i\n", $highestBlock - $currentBlock;
}

# account data
my $eth_accounts = geth_rpc('eth_accounts', []);
say 'Accounts: ' . $json->pretty->encode( $eth_accounts );

for my $account (@$eth_accounts) {
	# returned in wei 
	my $balance = hex geth_rpc( 'eth_getBalance', [ $account, 'latest' ] );
	$balance *= 1e-18;
	say "Balance ($account): $balance ether";
}
