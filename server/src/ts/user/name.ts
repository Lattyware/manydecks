import { default as UniqueNamesGenerator } from "unique-names-generator";

export const random = (): string =>
  UniqueNamesGenerator.uniqueNamesGenerator({
    dictionaries: [
      UniqueNamesGenerator.adjectives,
      UniqueNamesGenerator.colors,
      UniqueNamesGenerator.animals,
    ],
  });
