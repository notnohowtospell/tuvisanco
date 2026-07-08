import { Injectable, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {
    // Initialize Firebase Admin SDK
    // Note: Developer must configure GOOGLE_APPLICATION_CREDENTIALS or replace with manual cert config.
    if (admin.apps.length === 0) {
      try {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
      } catch (e) {
        console.warn('Firebase Admin SDK could not initialize: missing environment configuration. Please configure Service Account.');
      }
    }
  }

  async verifyFirebaseToken(token: string) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      const email = decodedToken.email;
      
      if (!email) {
        throw new UnauthorizedException('Firebase token does not contain an email');
      }

      const name = decodedToken.name || 'Bóng Thủ Mới';
      const avatarUrl = decodedToken.picture || '';

      // Find or create User in local PostgreSQL database
      let user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (!user) {
        user = await this.prisma.user.create({
          data: {
            email,
            fullName: name,
            avatarUrl,
            role: 'USER',
          },
        });
      }

      return user;
    } catch (error) {
      throw new UnauthorizedException('Invalid Firebase Token: ' + (error as Error).message);
    }
  }
}
