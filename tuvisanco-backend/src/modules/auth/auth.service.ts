import { Injectable, UnauthorizedException } from '@nestjs/common';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {
    // Initialize Firebase Admin SDK using modern modular API
    if (getApps().length === 0) {
      try {
        initializeApp(); // Automatically uses Application Default Credentials
      } catch (e) {
        console.warn('Firebase Admin SDK could not initialize: missing environment configuration. Please configure Service Account.');
      }
    }
  }


  async verifyFirebaseToken(token: string) {
    try {
      const decodedToken = await getAuth().verifyIdToken(token);
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

