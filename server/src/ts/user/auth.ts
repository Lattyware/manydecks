import { default as Jwt } from "jsonwebtoken";
import * as User from "../user";
import * as Errors from "../errors";

export interface Config {
  issuer: string;
  secret: string;
  algorithm: Jwt.Algorithm;
  historicAlgorithms: Jwt.Algorithm[];
  expiresIn: string;
}

export interface Claims {
  sub: User.Id;
}

export class Auth {
  private readonly config: Config;

  public constructor(config: Config) {
    this.config = config;
  }

  public sign(claims: Claims): string {
    const { secret, algorithm, issuer, expiresIn } = this.config;
    return Jwt.sign(claims, secret, { algorithm, issuer, expiresIn });
  }

  public validate(token: string): Claims {
    const { secret, algorithm, historicAlgorithms, issuer } = this.config;
    try {
      return Jwt.verify(token, secret, {
        algorithms: [algorithm, ...historicAlgorithms],
        issuer,
      }) as Claims;
    } catch (error) {
      throw new Errors.AuthFailure();
    }
  }
}
