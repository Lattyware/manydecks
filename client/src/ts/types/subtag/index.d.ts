declare module "subtag" {
  export default function subtag(
    code: string
  ): {
    language: string;
    extlang: string;
    script: string;
    region: string;
  };
}
