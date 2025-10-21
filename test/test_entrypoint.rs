use std::fs;

use litesvm::LiteSVM;

use solana_message::Message;
use solana_pubkey::Pubkey;
use solana_keypair::Keypair;
use solana_signer::Signer;
use solana_transaction::Transaction;
use solana_address::Address;

#[test]
fn test_entrypoint_logs_hello_from_nim() {
    let program_bytes = fs::read("build/program.so")
        .expect("Failed to read build/program.so - run ./build.sh first");

    let program_id = Pubkey::new_unique();
    let program_address = Address::from(program_id.to_bytes());
    let mut svm = LiteSVM::new();

    svm.add_program(program_address, &program_bytes)
        .expect("Failed to add program to SVM");

    let payer = Keypair::new();
    let payer_address = Address::from(payer.pubkey().to_bytes());
    svm.airdrop(&payer_address, 10_000_000_000)
        .expect("Failed to airdrop SOL");

    let instruction = solana_instruction::Instruction {
        program_id,
        accounts: vec![],
        data: vec![],
    };

    let message = Message::new(&[instruction], Some(&payer.pubkey()));
    let transaction = Transaction::new(&[&payer], message, svm.latest_blockhash());

    let result = svm.send_transaction(transaction);

    assert!(
        result.is_ok(),
        "Transaction should succeed: {:?}",
        result.err()
    );

    let logs = &result.unwrap().logs;
    let expected_message = "Hello from Nim!";
    let has_hello_from_nim = logs.iter().any(|log| log.contains(expected_message));

    assert!(
        has_hello_from_nim,
        "Logs should contain '{expected_message}'\nActual logs: {:#?}",
        logs
    );
}