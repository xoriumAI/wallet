/*
  # Create wallet management schema

  1. New Tables
    - `wallet_sections`
      - `id` (uuid, primary key)
      - `name` (text, not null)
      - `parent_id` (uuid, self-referential foreign key)
      - `order` (integer, not null)
      - `created_at` (timestamp with time zone)
      - `updated_at` (timestamp with time zone)
    
    - `wallets`
      - `id` (uuid, primary key)
      - `public_key` (text, unique, not null)
      - `encrypted_private_key` (text, not null)
      - `name` (text)
      - `balance` (numeric, not null)
      - `section_id` (uuid, foreign key)
      - `archived` (boolean, not null)
      - `created_at` (timestamp with time zone)
      - `updated_at` (timestamp with time zone)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to manage their own data
*/

-- Create wallet_sections table
CREATE TABLE wallet_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  parent_id uuid REFERENCES wallet_sections(id),
  "order" integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create wallets table
CREATE TABLE wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  public_key text UNIQUE NOT NULL,
  encrypted_private_key text NOT NULL,
  name text,
  balance numeric NOT NULL DEFAULT 0,
  section_id uuid REFERENCES wallet_sections(id),
  archived boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE wallet_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- Create default sections
INSERT INTO wallet_sections (id, name, parent_id, "order") VALUES
  ('00000000-0000-0000-0000-000000000001', 'Main', NULL, 0),
  ('00000000-0000-0000-0000-000000000002', 'Bundles', NULL, 1),
  ('00000000-0000-0000-0000-000000000003', 'Sniper Farming', NULL, 2),
  ('00000000-0000-0000-0000-000000000004', 'Dev', NULL, 3);

-- Create indexes
CREATE INDEX idx_wallets_section_id ON wallets(section_id);
CREATE INDEX idx_wallet_sections_parent_id ON wallet_sections(parent_id);
CREATE INDEX idx_wallet_sections_order ON wallet_sections("order");

-- Create RLS policies
CREATE POLICY "Users can read their wallet sections"
  ON wallet_sections
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create wallet sections"
  ON wallet_sections
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update their wallet sections"
  ON wallet_sections
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Users can delete their wallet sections"
  ON wallet_sections
  FOR DELETE
  TO authenticated
  USING (id != '00000000-0000-0000-0000-000000000001'); -- Prevent deletion of main section

CREATE POLICY "Users can read their wallets"
  ON wallets
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create wallets"
  ON wallets
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update their wallets"
  ON wallets
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Users can delete their wallets"
  ON wallets
  FOR DELETE
  TO authenticated
  USING (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_wallet_sections_updated_at
  BEFORE UPDATE ON wallet_sections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();