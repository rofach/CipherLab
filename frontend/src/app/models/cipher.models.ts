export type CipherOperation = 'Encrypt' | 'Decrypt';

export interface CipherRequest {
  text: string;
  operation: CipherOperation;
  shift: number;
  rails: number;
}

export interface CaesarStep {
  index: number;
  inputChar: string;
  outputChar: string;
  formula: string;
}

export interface CipherResponse {
  resultText: string;
  intermediateText: string;
  operation: CipherOperation;
  shift: number;
  rails: number;
  caesarSteps: CaesarStep[];
}
