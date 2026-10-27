use ring::rand::{SecureRandom, SystemRandom};
use ring::signature::{Ed25519KeyPair, KeyPair};

fn main() {
    let rng = SystemRandom::new();
    let mut seed = [0u8; 32];
    rng.fill(&mut seed).expect("random generation failed");
    let kp = Ed25519KeyPair::from_seed_unchecked(&seed).expect("bad key");
    let seed_hex: String = seed.iter().map(|b| format!("{b:02x}")).collect();
    let public_hex: String = kp.public_key().as_ref().iter().map(|b| format!("{b:02x}")).collect();

    println!("SEED: {seed_hex}");
    println!("PUBLIC: {public_hex}");
}
